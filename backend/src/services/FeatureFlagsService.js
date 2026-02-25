/**
 * Feature Flags Service
 * 
 * Core service for evaluating feature flags at runtime.
 * Handles:
 *   - Flag evaluation with caching
 *   - User targeting and percentage rollouts
 *   - Variant assignment for A/B tests
 *   - Canary stage progression
 *   - Metrics collection
 */

const redis = require('redis');
const crypto = require('crypto');
const flagConfig = require('../config/feature-flags');

class FeatureFlagsService {
  constructor(db, redisClient) {
    this.db = db;
    this.redis = redisClient;
    this.cacheKeyPrefix = 'feature_flag:';
    this.cacheExpireSecs = 5 * 60; // 5 minutes
    this.metrics = {
      checksTotal: 0,
      checksPerFlag: {},
      evaluationTimeMs: 0,
      lastUpdated: new Date()
    };
  }

  /**
   * Evaluate a feature flag for a user
   * @param {string} flagKey - The feature flag key
   * @param {string|number} userId - User ID for percentage/targeting
   * @param {object} context - Additional context (ip, segment, etc)
   * @returns {object} { enabled: boolean, variant: string, metadata: object }
   */
  async evaluateFlag(flagKey, userId = null, context = {}) {
    const startTime = Date.now();

    try {
      // Get flag configuration
      let flagConfig = await this.getFlagConfig(flagKey);
      if (!flagConfig) {
        return {
          enabled: false,
          variant: null,
          metadata: { reason: 'flag_not_found', cached: false }
        };
      }

      // Check if flag is disabled globally
      if (!flagConfig.enabled && flagConfig.type !== 'config') {
        this.recordMetric(flagKey);
        return {
          enabled: false,
          variant: null,
          metadata: { reason: 'globally_disabled', cached: false }
        };
      }

      let result = {
        enabled: false,
        variant: null,
        metadata: { 
          flagType: flagConfig.type,
          cached: false,
          reason: 'default'
        }
      };

      // Evaluate based on flag type
      switch (flagConfig.type) {
        case 'boolean':
          result = await this.evaluateBoolean(flagKey, flagConfig, userId, context);
          break;

        case 'canary':
          result = await this.evaluateCanary(flagKey, flagConfig, userId, context);
          break;

        case 'experiment':
          result = await this.evaluateExperiment(flagKey, flagConfig, userId, context);
          break;

        case 'config':
          result = {
            enabled: flagConfig.enabled,
            value: flagConfig.value,
            metadata: { flagType: 'config', cached: false }
          };
          break;

        default:
          result.metadata.reason = 'unknown_flag_type';
      }

      this.recordMetric(flagKey);
      result.evaluationTimeMs = Date.now() - startTime;
      return result;

    } catch (error) {
      console.error(`Error evaluating flag ${flagKey}:`, error);
      this.recordMetric(flagKey);
      return {
        enabled: false,
        variant: null,
        metadata: { 
          reason: 'evaluation_error',
          error: error.message 
        },
        evaluationTimeMs: Date.now() - startTime
      };
    }
  }

  /**
   * Evaluate boolean feature flag
   */
  async evaluateBoolean(flagKey, flagConfig, userId, context) {
    // Check user targeting list
    if (flagConfig.targetUsers && userId && flagConfig.targetUsers.includes(String(userId))) {
      return {
        enabled: true,
        variant: null,
        metadata: {
          reason: 'user_targeted',
          cached: false
        }
      };
    }

    // Check percentage rollout
    if (userId && flagConfig.percentage > 0) {
      const userHash = this.hashUserId(flagKey, userId);
      if (userHash < flagConfig.percentage) {
        return {
          enabled: true,
          variant: null,
          metadata: {
            reason: 'percentage_rollout',
            userHash,
            cached: false
          }
        };
      }
    }

    return {
      enabled: false,
      variant: null,
      metadata: {
        reason: 'not_in_rollout',
        cached: false
      }
    };
  }

  /**
   * Evaluate canary deployment flag
   */
  async evaluateCanary(flagKey, flagConfig, userId, context) {
    // Get current canary stage
    const stage = flagConfig.stages[flagConfig.currentStage] || flagConfig.stages[0];
    const stagePercentage = stage.percentage;

    // Check if we should move to next stage
    await this.checkCanaryStageProgression(flagKey, flagConfig);

    // Determine if user is in canary group
    if (userId) {
      const userHash = this.hashUserId(flagKey, userId);
      if (userHash < stagePercentage) {
        return {
          enabled: true,
          variant: stage.name,
          metadata: {
            reason: 'canary_rollout',
            stage: stage.name,
            percentage: stagePercentage,
            cached: false
          }
        };
      }
    } else if (context.ipAddress) {
      // IP-based canary for unauthenticated users
      const ipHash = this.hashValue(flagKey + context.ipAddress);
      if (ipHash < stagePercentage) {
        return {
          enabled: true,
          variant: stage.name,
          metadata: {
            reason: 'canary_rollout_ip',
            stage: stage.name,
            percentage: stagePercentage,
            cached: false
          }
        };
      }
    }

    return {
      enabled: false,
      variant: null,
      metadata: {
        reason: 'not_in_canary',
        currentCanaryStage: stagePercentage,
        cached: false
      }
    };
  }

  /**
   * Evaluate A/B test experiment flag
   */
  async evaluateExperiment(flagKey, flagConfig, userId, context) {
    if (!userId) {
      return {
        enabled: false,
        variant: null,
        metadata: {
          reason: 'user_required_for_experiment',
          cached: false
        }
      };
    }

    // Generate consistent variant for user
    const userHash = this.hashUserId(flagKey, userId);
    
    let cumulativePercentage = 0;
    for (const [variantKey, variantConfig] of Object.entries(flagConfig.variants)) {
      cumulativePercentage += variantConfig.percentage;
      
      if (userHash < cumulativePercentage) {
        return {
          enabled: true,
          variant: variantKey,
          metadata: {
            reason: 'experiment_variant',
            variantDescription: variantConfig.description,
            cached: false
          }
        };
      }
    }

    // Fallback to first variant
    const firstVariant = Object.keys(flagConfig.variants)[0];
    return {
      enabled: true,
      variant: firstVariant,
      metadata: {
        reason: 'experiment_default',
        cached: false
      }
    };
  }

  /**
   * Get flag configuration from cache or database
   */
  async getFlagConfig(flagKey) {
    const cacheKey = `${this.cacheKeyPrefix}${flagKey}`;

    try {
      // Try cache first
      const cached = await this.redis.get(cacheKey);
      if (cached) {
        return JSON.parse(cached);
      }
    } catch (err) {
      console.error('Cache error:', err);
    }

    // Try database
    try {
      const flag = await this.db('feature_flags')
        .where('key', flagKey)
        .first();

      if (flag) {
        const config = JSON.parse(flag.config);
        await this.redis.set(cacheKey, JSON.stringify(config), 'EX', this.cacheExpireSecs);
        return config;
      }
    } catch (err) {
      console.error('Database error:', err);
    }

    // Fall back to in-memory defaults
    return flagConfig.defaultFlags[flagKey] || null;
  }

  /**
   * Check if canary deployment should advance to next stage
   */
  async checkCanaryStageProgression(flagKey, flagConfig) {
    if (!flagConfig.stageStartedAt) {
      flagConfig.stageStartedAt = Date.now();
      return;
    }

    const currentStage = flagConfig.stages[flagConfig.currentStage];
    const elapsedMinutes = (Date.now() - flagConfig.stageStartedAt) / (60 * 1000);

    if (elapsedMinutes >= currentStage.durationMinutes && currentStage.durationMinutes > 0) {
      // Check if next stage exists and not already at 100%
      if (flagConfig.currentStage < flagConfig.stages.length - 1) {
        flagConfig.currentStage += 1;
        flagConfig.stageStartedAt = Date.now();

        // Save to database
        try {
          await this.db('feature_flags')
            .where('key', flagKey)
            .update({
              config: JSON.stringify(flagConfig),
              updated_at: new Date()
            });

          // Invalidate cache
          await this.redis.del(`${this.cacheKeyPrefix}${flagKey}`);

          console.log(`Canary flag ${flagKey} advanced to stage ${flagConfig.currentStage}`);
        } catch (err) {
          console.error(`Failed to update canary stage for ${flagKey}:`, err);
        }
      }
    }
  }

  /**
   * Hash user ID for consistent percentage rollout
   * Returns 0-100 hash value
   */
  hashUserId(flagKey, userId) {
    return this.hashValue(`${flagKey}:${userId}`);
  }

  /**
   * Generate consistent hash (0-100)
   */
  hashValue(value) {
    const hash = crypto.createHash('md5').update(value).digest('hex');
    return parseInt(hash.substring(0, 8), 16) % 100;
  }

  /**
   * Get all flags for monitoring/management
   */
  async getAllFlags() {
    try {
      const cached = await this.redis.get(`${this.cacheKeyPrefix}all`);
      if (cached) {
        return JSON.parse(cached);
      }
    } catch (err) {
      console.error('Cache error:', err);
    }

    try {
      const flags = await this.db('feature_flags').select('key', 'config', 'created_at', 'updated_at');
      const flagMap = {};

      for (const flag of flags) {
        flagMap[flag.key] = JSON.parse(flag.config);
      }

      await this.redis.set(
        `${this.cacheKeyPrefix}all`,
        JSON.stringify(flagMap),
        'EX',
        this.cacheExpireSecs
      );

      return flagMap;
    } catch (err) {
      console.error('Database error:', err);
      return flagConfig.getEnvironmentConfig();
    }
  }

  /**
   * Update a feature flag
   */
  async updateFlag(flagKey, updates) {
    try {
      const flag = await this.getFlagConfig(flagKey);
      const updated = { ...flag, ...updates, updated_at: new Date() };

      flagConfig.validateFlag(updated);

      await this.db('feature_flags')
        .where('key', flagKey)
        .update({
          config: JSON.stringify(updated),
          updated_at: new Date()
        });

      // Invalidate caches
      await this.redis.del(`${this.cacheKeyPrefix}${flagKey}`);
      await this.redis.del(`${this.cacheKeyPrefix}all`);

      return updated;
    } catch (err) {
      console.error(`Error updating flag ${flagKey}:`, err);
      throw err;
    }
  }

  /**
   * Record metric for flag evaluation
   */
  recordMetric(flagKey) {
    this.metrics.checksTotal++;
    this.metrics.checksPerFlag[flagKey] = (this.metrics.checksPerFlag[flagKey] || 0) + 1;
    this.metrics.lastUpdated = new Date();
  }

  /**
   * Get metrics
   */
  getMetrics() {
    return {
      ...this.metrics,
      timestamp: new Date().toISOString()
    };
  }
}

module.exports = FeatureFlagsService;
