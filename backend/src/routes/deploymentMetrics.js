/**
 * Feature Flags and Deployment Metrics API Routes
 * 
 * Admin endpoints for:
 *   - Getting and updating feature flags
 *   - Monitoring deployment metrics
 *   - Triggering/cancelling canary stages
 *   - Analyzing A/B test results
 *   - Viewing deployment health
 */

const express = require('express');
const router = express.Router();

/**
 * Initialize routes with services
 */
function initializeRoutes(featureFlagsService, deploymentMetricsService) {
  /**
   * GET /api/admin/feature-flags
   * Get all feature flags
   */
  router.get('/feature-flags', async (req, res) => {
    try {
      const flags = await featureFlagsService.getAllFlags();
      res.json({
        success: true,
        data: flags,
        count: Object.keys(flags).length,
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  });

  /**
   * GET /api/admin/feature-flags/:flagKey
   * Get specific feature flag
   */
  router.get('/feature-flags/:flagKey', async (req, res) => {
    try {
      const flag = await featureFlagsService.getFlagConfig(req.params.flagKey);
      
      if (!flag) {
        return res.status(404).json({
          success: false,
          error: 'Feature flag not found'
        });
      }

      res.json({
        success: true,
        data: flag,
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  });

  /**
   * PUT /api/admin/feature-flags/:flagKey
   * Update feature flag
   * 
   * Body:
   * {
   *   "enabled": true,
   *   "percentage": 50,
   *   "targetUsers": [123, 456],
   *   "currentStage": 2 (for canary),
   *   "variants": { "control": 50, "variant_a": 50 } (for experiments)
   * }
   */
  router.put('/feature-flags/:flagKey', async (req, res) => {
    try {
      const { flagKey } = req.params;
      const updates = req.body;

      // Log the change
      console.log(`Updating feature flag: ${flagKey}`, {
        by: req.user?.id || 'system',
        changes: updates,
        timestamp: new Date().toISOString()
      });

      const updated = await featureFlagsService.updateFlag(flagKey, updates);

      // Record deployment event for significant changes
      if (updates.enabled || updates.percentage !== undefined || updates.currentStage !== undefined) {
        deploymentMetricsService.recordDeploymentEvent({
          type: 'flag_updated',
          version: process.env.DEPLOYMENT_VERSION || 'unknown',
          metadata: {
            flagKey,
            changes: updates,
            updatedBy: req.user?.id || 'system'
          }
        });
      }

      res.json({
        success: true,
        data: updated,
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        error: error.message
      });
    }
  });

  /**
   * POST /api/admin/feature-flags/:flagKey/advance-canary
   * Manually advance canary to next stage
   */
  router.post('/feature-flags/:flagKey/advance-canary', async (req, res) => {
    try {
      const { flagKey } = req.params;
      const flag = await featureFlagsService.getFlagConfig(flagKey);

      if (!flag || flag.type !== 'canary') {
        return res.status(404).json({
          success: false,
          error: 'Canary flag not found'
        });
      }

      if (flag.currentStage >= flag.stages.length - 1) {
        return res.status(400).json({
          success: false,
          error: 'Already at final stage'
        });
      }

      const nextStageIndex = flag.currentStage + 1;
      const updated = await featureFlagsService.updateFlag(flagKey, {
        currentStage: nextStageIndex,
        stageStartedAt: Date.now()
      });

      deploymentMetricsService.recordDeploymentEvent({
        type: 'canary_stage_advanced',
        version: process.env.DEPLOYMENT_VERSION || 'unknown',
        canaryStage: updated.stages[nextStageIndex].name,
        affectedUsers: Math.floor(updated.stages[nextStageIndex].percentage / 100 * 1000000) // Estimate
      });

      res.json({
        success: true,
        message: `Advanced to stage ${nextStageIndex + 1} (${updated.stages[nextStageIndex].name})`,
        data: updated,
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  });

  /**
   * POST /api/admin/feature-flags/:flagKey/rollback-canary
   * Rollback canary to previous stage
   */
  router.post('/feature-flags/:flagKey/rollback-canary', async (req, res) => {
    try {
      const { flagKey } = req.params;
      const { reason = 'Manual rollback' } = req.body;
      const flag = await featureFlagsService.getFlagConfig(flagKey);

      if (!flag || flag.type !== 'canary') {
        return res.status(404).json({
          success: false,
          error: 'Canary flag not found'
        });
      }

      if (flag.currentStage === 0) {
        return res.status(400).json({
          success: false,
          error: 'Already at initial stage'
        });
      }

      const previousStageIndex = flag.currentStage - 1;
      const updated = await featureFlagsService.updateFlag(flagKey, {
        currentStage: previousStageIndex,
        stageStartedAt: Date.now()
      });

      deploymentMetricsService.recordDeploymentEvent({
        type: 'canary_rollback',
        version: process.env.DEPLOYMENT_VERSION || 'unknown',
        canaryStage: updated.stages[previousStageIndex].name,
        metadata: { reason }
      });

      res.json({
        success: true,
        message: `Rolled back to stage ${previousStageIndex + 1} (${updated.stages[previousStageIndex].name})`,
        data: updated,
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  });

  /**
   * GET /api/admin/metrics/health
   * Get current deployment health status
   */
  router.get('/metrics/health', async (req, res) => {
    try {
      const health = await deploymentMetricsService.getHealthStatus();
      res.json({
        success: true,
        data: health,
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  });

  /**
   * GET /api/admin/metrics/range
   * Get metrics for time range
   * 
   * Query params:
   * - startTime: ISO datetime (required)
   * - endTime: ISO datetime (required)
   */
  router.get('/metrics/range', async (req, res) => {
    try {
      const { startTime, endTime } = req.query;

      if (!startTime || !endTime) {
        return res.status(400).json({
          success: false,
          error: 'startTime and endTime query parameters required'
        });
      }

      const metrics = await deploymentMetricsService.getMetricsRange(
        new Date(startTime),
        new Date(endTime)
      );

      res.json({
        success: true,
        data: metrics,
        count: metrics.length,
        timeline: {
          start: startTime,
          end: endTime
        },
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  });

  /**
   * GET /api/admin/metrics/flag-usage
   * Get feature flag usage metrics
   */
  router.get('/metrics/flag-usage', (req, res) => {
    try {
      const metrics = featureFlagsService.getMetrics();
      res.json({
        success: true,
        data: metrics,
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  });

  /**
   * GET /api/admin/experiments/:experimentKey/results
   * Get A/B test results
   */
  router.get('/experiments/:experimentKey/results', async (req, res) => {
    try {
      const { experimentKey } = req.params;
      const { startTime, endTime } = req.query;

      const flag = await featureFlagsService.getFlagConfig(experimentKey);

      if (!flag || flag.type !== 'experiment') {
        return res.status(404).json({
          success: false,
          error: 'Experiment flag not found'
        });
      }

      const metrics = await deploymentMetricsService.getMetricsRange(
        new Date(startTime || Date.now() - 24 * 60 * 60 * 1000),
        new Date(endTime || Date.now())
      );

      const variantResults = {};

      // Aggregate metrics by variant
      metrics.forEach(metric => {
        if (metric.byExperimentVariant && metric.byExperimentVariant[experimentKey]) {
          const variant = metric.byExperimentVariant[experimentKey];

          variantResults[variant] = {
            count: (variantResults[variant]?.count || 0) + variant.count,
            errors: (variantResults[variant]?.errors || 0) + variant.errors,
            totalResponseTime: (variantResults[variant]?.totalResponseTime || 0) + variant.totalResponseTime
          };
        }
      });

      // Calculate statistics
      Object.keys(variantResults).forEach(variant => {
        const result = variantResults[variant];
        result.errorRate = (result.errors / result.count) * 100;
        result.avgResponseTime = result.totalResponseTime / result.count;
      });

      res.json({
        success: true,
        experimentKey,
        flag,
        variantResults,
        timeline: {
          start: startTime || new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString(),
          end: endTime || new Date().toISOString()
        },
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  });

  /**
   * GET /api/admin/experiments/:experimentKey/statistical-significance
   * Calculate statistical significance of experiment results
   */
  router.get('/experiments/:experimentKey/statistical-significance', async (req, res) => {
    try {
      const { experimentKey } = req.params;
      const { metric = 'errorRate' } = req.query;

      const flag = await featureFlagsService.getFlagConfig(experimentKey);

      if (!flag || flag.type !== 'experiment') {
        return res.status(404).json({
          success: false,
          error: 'Experiment flag not found'
        });
      }

      const metrics = await deploymentMetricsService.getMetricsRange(
        new Date(Date.now() - 24 * 60 * 60 * 1000),
        new Date()
      );

      // Collect variant measurements
      const variantMetrics = {};

      metrics.forEach(m => {
        if (m.byExperimentVariant) {
          Object.entries(m.byExperimentVariant).forEach(([variant, stats]) => {
            if (variant === experimentKey) {
              if (!variantMetrics[variant]) variantMetrics[variant] = [];
              variantMetrics[variant].push(stats[metric] || 0);
            }
          });
        }
      });

      // Perform t-test
      const significance = calculateTTest(variantMetrics);

      res.json({
        success: true,
        experimentKey,
        metric,
        results: significance,
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  });

  return router;
}

/**
 * Simple t-test implementation
 * Returns p-value to determine statistical significance
 */
function calculateTTest(variantMetrics) {
  const variants = Object.entries(variantMetrics);
  
  if (variants.length < 2) {
    return {
      error: 'Need at least 2 variants',
      samples: Object.fromEntries(variants.map(([name, values]) => [name, {
        count: values.length,
        mean: values.reduce((a, b) => a + b, 0) / values.length,
        stdDev: standardDeviation(values)
      }]))
    };
  }

  const [
    [variantA, samplesA],
    [variantB, samplesB]
  ] = variants;

  const meanA = samplesA.reduce((a, b) => a + b, 0) / samplesA.length;
  const meanB = samplesB.reduce((a, b) => a + b, 0) / samplesB.length;
  const stdA = standardDeviation(samplesA);
  const stdB = standardDeviation(samplesB);

  const t = (meanA - meanB) / Math.sqrt(
    (stdA ** 2 / samplesA.length) + (stdB ** 2 / samplesB.length)
  );

  const pValue = 2 * (1 - tCDF(Math.abs(t), samplesA.length + samplesB.length - 2));

  return {
    winner: meanA > meanB ? variantA : variantB,
    isSignificant: pValue < 0.05,
    pValue: pValue.toFixed(4),
    confidence: ((1 - pValue) * 100).toFixed(2) + '%',
    samples: {
      [variantA]: {
        count: samplesA.length,
        mean: meanA.toFixed(4),
        stdDev: stdA.toFixed(4)
      },
      [variantB]: {
        count: samplesB.length,
        mean: meanB.toFixed(4),
        stdDev: stdB.toFixed(4)
      }
    }
  };
}

function standardDeviation(arr) {
  const mean = arr.reduce((a, b) => a + b, 0) / arr.length;
  const variance = arr.reduce((sum, val) => sum + Math.pow(val - mean, 2), 0) / arr.length;
  return Math.sqrt(variance);
}

function tCDF(t, df) {
  // Approximate t-distribution CDF
  // In production, use a proper statistics library
  const beta = Math.log(1 + (t * t) / df) / 2;
  return 0.5 + (1 / Math.PI) * Math.atan(t / Math.sqrt(df)) - 0.5 * Math.exp(beta) / df;
}

module.exports = initializeRoutes;
