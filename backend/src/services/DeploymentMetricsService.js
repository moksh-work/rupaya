/**
 * Deployment Metrics Service
 * 
 * Collects and analyzes metrics for:
 *   - Canary deployment monitoring
 *   - Automated rollback decision-making
 *   - A/B test result tracking
 *   - Health checks
 */

const EventEmitter = require('events');

class DeploymentMetricsService extends EventEmitter {
  constructor(redis, featureFlagsService) {
    super();
    this.redis = redis;
    this.featureFlagsService = featureFlagsService;
    this.metricsPrefix = 'metrics:';
    this.windowSizeSeconds = 60; // 1-minute window
    this.aggregationInterval = 10000; // 10 seconds

    // In-memory buffer for real-time metrics
    this.buffer = {
      requests: [],
      errors: [],
      responseTimes: [],
      deploymentEvents: []
    };

    // Start aggregation worker
    this.aggregationTimer = setInterval(
      () => this.aggregateMetrics(),
      this.aggregationInterval
    );

    // Cleanup old metrics periodically
    this.cleanupTimer = setInterval(
      () => this.cleanupOldMetrics(),
      5 * 60 * 1000 // Every 5 minutes
    );
  }

  /**
   * Record request metric
   */
  recordRequest(options = {}) {
    const metric = {
      timestamp: Date.now(),
      userId: options.userId || null,
      method: options.method || 'GET',
      path: options.path || '/',
      statusCode: options.statusCode || 200,
      responseTimeMs: options.responseTimeMs || 0,
      errorCode: options.errorCode || null,
      deploymentVersion: options.deploymentVersion || null,
      canaryStage: options.canaryStage || null,
      experimentVariant: options.experimentVariant || null,
      tags: options.tags || {}
    };

    this.buffer.requests.push(metric);

    // Track error
    if (metric.statusCode >= 400) {
      this.buffer.errors.push(metric);
    }

    // Track response time
    this.buffer.responseTimes.push({
      timestamp: metric.timestamp,
      responseTimeMs: metric.responseTimeMs,
      path: metric.path
    });

    return metric;
  }

  /**
   * Record deployment event
   */
  recordDeploymentEvent(options = {}) {
    const event = {
      timestamp: Date.now(),
      type: options.type, // 'canary_stage_start', 'canary_stage_end', 'rollback', etc
      version: options.version,
      canaryStage: options.canaryStage || null,
      successCount: options.successCount || 0,
      errorCount: options.errorCount || 0,
      affectedUsers: options.affectedUsers || 0
    };

    this.buffer.deploymentEvents.push(event);
    this.emit('deployment:event', event);

    return event;
  }

  /**
   * Aggregate metrics for analysis
   */
  async aggregateMetrics() {
    if (this.buffer.requests.length === 0) {
      return;
    }

    try {
      const now = Date.now();
      const windowStart = now - (this.windowSizeSeconds * 1000);

      // Filter metrics in current window
      const recentRequests = this.buffer.requests.filter(r => r.timestamp > windowStart);
      const recentErrors = this.buffer.errors.filter(e => e.timestamp > windowStart);
      const recentResponseTimes = this.buffer.responseTimes.filter(r => r.timestamp > windowStart);

      if (recentRequests.length === 0) {
        return;
      }

      // Calculate aggregates
      const aggregate = {
        windowStartTime: new Date(windowStart),
        windowEndTime: new Date(now),
        totalRequests: recentRequests.length,
        totalErrors: recentErrors.length,
        errorRate: (recentErrors.length / recentRequests.length) * 100,
        p50ResponseTime: this.percentile(recentResponseTimes.map(r => r.responseTimeMs), 50),
        p95ResponseTime: this.percentile(recentResponseTimes.map(r => r.responseTimeMs), 95),
        p99ResponseTime: this.percentile(recentResponseTimes.map(r => r.responseTimeMs), 99),
        avgResponseTime: recentResponseTimes.reduce((sum, r) => sum + r.responseTimeMs, 0) / recentResponseTimes.length,
        requestsPerSecond: recentRequests.length / this.windowSizeSeconds,
        topErrors: this.getTopErrors(recentErrors),
        byEndpoint: this.groupByEndpoint(recentRequests),
        byCanaryStage: this.groupByCanaryStage(recentRequests),
        byExperimentVariant: this.groupByExperimentVariant(recentRequests)
      };

      // Check for rollback conditions
      await this.checkRollbackConditions(aggregate);

      // Save to Redis
      const metricsKey = `${this.metricsPrefix}${Math.floor(now / 1000)}`;
      await this.redis.set(metricsKey, JSON.stringify(aggregate), 'EX', 600); // Keep 10 minutes

      // Emit event for subscribers
      this.emit('metrics:aggregated', aggregate);

      // Keep only recent metrics in buffer
      this.buffer.requests = recentRequests;
      this.buffer.errors = recentErrors;
      this.buffer.responseTimes = recentResponseTimes;

    } catch (err) {
      console.error('Error aggregating metrics:', err);
    }
  }

  /**
   * Check if rollback should be triggered
   */
  async checkRollbackConditions(aggregate) {
    try {
      const errorRateThreshold = await this.featureFlagsService.evaluateFlag(
        'rollback.error-rate-threshold'
      );
      const responseTimeThreshold = await this.featureFlagsService.evaluateFlag(
        'rollback.response-time-threshold'
      );

      const shouldRollback =
        (errorRateThreshold.value && aggregate.errorRate > errorRateThreshold.value) ||
        (responseTimeThreshold.value && aggregate.p99ResponseTime > responseTimeThreshold.value);

      if (shouldRollback) {
        this.emit('rollback:triggered', {
          reason: this.analyzeRollbackReason(aggregate, errorRateThreshold, responseTimeThreshold),
          metrics: aggregate,
          timestamp: new Date()
        });
      }

    } catch (err) {
      console.error('Error checking rollback conditions:', err);
    }
  }

  /**
   * Analyze why rollback was triggered
   */
  analyzeRollbackReason(aggregate, errorThreshold, timeThreshold) {
    const reasons = [];

    if (errorThreshold.value && aggregate.errorRate > errorThreshold.value) {
      reasons.push(`Error rate ${aggregate.errorRate.toFixed(2)}% exceeds threshold ${errorThreshold.value}%`);
    }

    if (timeThreshold.value && aggregate.p99ResponseTime > timeThreshold.value) {
      reasons.push(`P99 response time ${aggregate.p99ResponseTime.toFixed(0)}ms exceeds threshold ${timeThreshold.value}ms`);
    }

    return reasons;
  }

  /**
   * Get metrics for a time range
   */
  async getMetricsRange(startTime, endTime) {
    try {
      const startTimestamp = Math.floor(startTime.getTime() / 1000);
      const endTimestamp = Math.floor(endTime.getTime() / 1000);

      const metrics = [];
      
      for (let ts = startTimestamp; ts <= endTimestamp; ts++) {
        const metricsKey = `${this.metricsPrefix}${ts}`;
        const data = await this.redis.get(metricsKey);
        if (data) {
          metrics.push(JSON.parse(data));
        }
      }

      return metrics;
    } catch (err) {
      console.error('Error getting metrics range:', err);
      return [];
    }
  }

  /**
   * Get current health status
   */
  async getHealthStatus() {
    const recentMetrics = await this.getMetricsRange(
      new Date(Date.now() - 5 * 60 * 1000), // Last 5 minutes
      new Date()
    );

    if (recentMetrics.length === 0) {
      return {
        status: 'healthy',
        message: 'No recent metrics',
        metrics: null
      };
    }

    const latest = recentMetrics[recentMetrics.length - 1];

    return {
      status: this.getHealthStatus(latest) ? 'healthy' : 'degraded',
      errorRate: latest.errorRate,
      p99ResponseTime: latest.p99ResponseTime,
      requestsPerSecond: latest.requestsPerSecond,
      topErrors: latest.topErrors,
      timestamp: new Date()
    };
  }

  /**
   * Determine health status based on metrics
   */
  isHealthy(metrics) {
    return metrics.errorRate < 5 && metrics.p99ResponseTime < 2000;
  }

  /**
   * Calculate percentile from array
   */
  percentile(arr, p) {
    if (arr.length === 0) return 0;
    
    const sorted = arr.sort((a, b) => a - b);
    const index = Math.ceil((sorted.length * p) / 100) - 1;
    return sorted[Math.max(0, index)];
  }

  /**
   * Get top errors
   */
  getTopErrors(errors) {
    const errorMap = {};

    errors.forEach(err => {
      const key = `${err.method} ${err.path} - ${err.statusCode}`;
      errorMap[key] = (errorMap[key] || 0) + 1;
    });

    return Object.entries(errorMap)
      .sort(([, countA], [, countB]) => countB - countA)
      .slice(0, 5)
      .map(([error, count]) => ({ error, count }));
  }

  /**
   * Group metrics by endpoint
   */
  groupByEndpoint(requests) {
    const grouped = {};

    requests.forEach(req => {
      const key = `${req.method} ${req.path}`;
      if (!grouped[key]) {
        grouped[key] = {
          count: 0,
          errors: 0,
          totalResponseTime: 0,
          avgResponseTime: 0
        };
      }

      grouped[key].count++;
      if (req.statusCode >= 400) grouped[key].errors++;
      grouped[key].totalResponseTime += req.responseTimeMs;
    });

    // Calculate averages
    Object.values(grouped).forEach(stat => {
      stat.avgResponseTime = stat.totalResponseTime / stat.count;
      stat.errorRate = (stat.errors / stat.count) * 100;
    });

    return grouped;
  }

  /**
   * Group metrics by canary stage
   */
  groupByCanaryStage(requests) {
    const grouped = {};

    requests.filter(r => r.canaryStage).forEach(req => {
      const stage = req.canaryStage;
      if (!grouped[stage]) {
        grouped[stage] = {
          count: 0,
          errors: 0,
          totalResponseTime: 0
        };
      }

      grouped[stage].count++;
      if (req.statusCode >= 400) grouped[stage].errors++;
      grouped[stage].totalResponseTime += req.responseTimeMs;
    });

    // Calculate rates
    Object.values(grouped).forEach(stat => {
      stat.errorRate = (stat.errors / stat.count) * 100;
      stat.avgResponseTime = stat.totalResponseTime / stat.count;
    });

    return grouped;
  }

  /**
   * Group metrics by experiment variant
   */
  groupByExperimentVariant(requests) {
    const grouped = {};

    requests.filter(r => r.experimentVariant).forEach(req => {
      const variant = req.experimentVariant;
      if (!grouped[variant]) {
        grouped[variant] = {
          count: 0,
          errors: 0,
          totalResponseTime: 0
        };
      }

      grouped[variant].count++;
      if (req.statusCode >= 400) grouped[variant].errors++;
      grouped[variant].totalResponseTime += req.responseTimeMs;
    });

    // Calculate metrics
    Object.values(grouped).forEach(stat => {
      stat.errorRate = (stat.errors / stat.count) * 100;
      stat.avgResponseTime = stat.totalResponseTime / stat.count;
    });

    return grouped;
  }

  /**
   * Cleanup old metrics from Redis
   */
  async cleanupOldMetrics() {
    try {
      // Keep metrics for last hour (3600 seconds)
      const cutoffTimestamp = Math.floor(Date.now() / 1000) - 3600;
      
      // In a real system, you'd scan and delete old keys
      // For now, rely on Redis expiration (EX setting)
      console.log(`Metrics cleanup: keeping data after ${new Date(cutoffTimestamp * 1000).toISOString()}`);
    } catch (err) {
      console.error('Error cleaning up metrics:', err);
    }
  }

  /**
   * Shutdown service and cleanup
   */
  shutdown() {
    clearInterval(this.aggregationTimer);
    clearInterval(this.cleanupTimer);
    this.removeAllListeners();
  }
}

module.exports = DeploymentMetricsService;
