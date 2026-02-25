/**
 * Feature Flags and Metrics Middleware
 * 
 * Integrates feature flag evaluation and metrics collection
 * into the request/response cycle
 */

module.exports = (featureFlagsService, deploymentMetricsService) => {
  return (req, res, next) => {
    const startTime = Date.now();

    // Add feature flag evaluation helper to request
    req.evaluateFlag = async (flagKey, context = {}) => {
      const userId = req.user?.id;
      const ipAddress = req.ip || req.connection.remoteAddress;
      
      return featureFlagsService.evaluateFlag(flagKey, userId, {
        ipAddress,
        ...context
      });
    };

    // Get all flags helper
    req.getAllFlags = () => featureFlagsService.getAllFlags();

    // Get flag metrics helper
    req.getFlagMetrics = () => featureFlagsService.getMetrics();

    // Intercept response to collect metrics
    const originalSend = res.send;
    const originalJson = res.json;

    const collectMetrics = (statusCode) => {
      const responseTimeMs = Date.now() - startTime;
      
      deploymentMetricsService.recordRequest({
        userId: req.user?.id || null,
        method: req.method,
        path: req.path,
        statusCode: statusCode,
        responseTimeMs,
        deploymentVersion: process.env.DEPLOYMENT_VERSION || 'unknown',
        canaryStage: req.canaryStage || null,
        experimentVariant: req.experimentVariant || null,
        tags: {
          endpoint: `${req.method} ${req.baseUrl}${req.path}`,
          authenticated: !!req.user,
          ...req.metricsTags
        }
      });
    };

    res.send = function(data) {
      collectMetrics(this.statusCode);
      return originalSend.call(this, data);
    };

    res.json = function(data) {
      collectMetrics(this.statusCode);
      return originalJson.call(this, data);
    };

    next();
  };
};
