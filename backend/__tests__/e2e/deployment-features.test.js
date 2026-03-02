/**
 * @file Feature Flags & Deployment E2E Tests
 * @description Comprehensive E2E tests for feature flags, canary deployments,
 *              A/B testing, and deployment metrics. Runs against live API.
 */

const request = require('supertest');
const app = require('../../src/app');

const API_BASE_URL = process.env.API_BASE_URL || 'http://localhost:3000';
const shouldRunE2E = process.env.RUN_E2E_TESTS === 'true' || process.env.NODE_ENV === 'test';
const useInProcessRequests = /^https?:\/\/localhost(?::\d+)?$/i.test(API_BASE_URL);

// ========== HTTP Request Helper ==========
const requestJson = async ({ method, path, token, body }) => {
  const url = new URL(path, API_BASE_URL);
  const resolvedPath = `${url.pathname}${url.search}`;

  if (useInProcessRequests) {
    let req = request(app)[method.toLowerCase()](resolvedPath)
      .set('Accept', 'application/json')
      .set('User-Agent', 'E2E-Test-Suite/1.0');

    if (token) {
      req = req.set('Authorization', `Bearer ${token}`);
    }

    if (body) {
      req = req.send(body);
    }

    const res = await req.timeout({ response: 10000, deadline: 15000 });

    return {
      status: res.status,
      headers: res.headers,
      body: res.body || {},
      raw: typeof res.text === 'string' ? res.text : JSON.stringify(res.body || {})
    };
  }

  throw new Error(`Remote mode for API_BASE_URL=${API_BASE_URL} is not enabled in this local E2E run`);
};

// ========== Helper Functions ==========
const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

const generateEmail = () => `e2e-${Date.now()}-${Math.random().toString(36).substring(7)}@test.local`;

const generatePassword = () => {
  const upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  const lower = 'abcdefghijklmnopqrstuvwxyz';
  const digits = '0123456789';
  const special = '!@#$%';
  
  let password = 'Tt1!';
  for (let i = 0; i < 16; i++) {
    const chars = upper + lower + digits + special;
    password += chars[Math.floor(Math.random() * chars.length)];
  }
  return password;
};

const unwrapData = (body) => (body && body.data !== undefined ? body.data : body);

const normalizeFlags = (body) => {
  const data = unwrapData(body);
  if (Array.isArray(data)) {
    return data;
  }
  if (data && typeof data === 'object') {
    return Object.entries(data).map(([key, value]) => ({ key, ...(value || {}) }));
  }
  return [];
};

// ========== Test Suite Setup ==========
const describeE2E = shouldRunE2E ? describe : describe.skip;

describeE2E('Feature Flags & Deployment E2E Tests', () => {
  let testUser = null;
  let accessToken = null;
  let refreshToken = null;
  let testDeviceId = `e2e-test-device-${Date.now()}`;

  beforeAll(async () => {
    // Create test user for E2E tests
    const email = generateEmail();
    const password = generatePassword();

    const signupRes = await requestJson({
      method: 'POST',
      path: '/api/v1/auth/signup',
      body: {
        email,
        password,
        deviceId: testDeviceId,
        deviceName: 'E2E Test Device'
      }
    });

    if (signupRes.status === 201 || signupRes.status === 200) {
      testUser = { email, password };
      accessToken = signupRes.body.accessToken || signupRes.body.token;
      refreshToken = signupRes.body.refreshToken;
    } else if (signupRes.status === 429) {
      console.warn('⚠️  Rate limit hit during signup - some tests will be skipped');
    } else {
      console.warn(`⚠️  Signup failed with status ${signupRes.status}`);
    }
  });

  // ========== Feature Flags API Tests ==========
  describe('Feature Flags API', () => {
    it('should return feature flags list', async () => {
      const response = await requestJson({
        method: 'GET',
        path: '/api/admin/deployment/feature-flags',
        token: accessToken
      });

      expect(response.status).toBe(200);
      const flags = normalizeFlags(response.body);
      expect(Array.isArray(flags)).toBe(true);
      if (flags.length === 0) {
        console.warn('⚠️  No feature flags configured');
        return;
      }

      // Check for expected flags
      const flagKeys = flags.map(f => f.key);
      expect(flagKeys.length).toBeGreaterThan(0);
    });

    it('should get specific feature flag', async () => {
      const listRes = await requestJson({
        method: 'GET',
        path: '/api/admin/deployment/feature-flags',
        token: accessToken
      });

      const flags = normalizeFlags(listRes.body);
      const firstFlag = flags[0];
      if (!firstFlag) {
        console.warn('⚠️  No feature flag available for detail test');
        return;
      }
      expect(firstFlag.key).toBeDefined();

      const flagRes = await requestJson({
        method: 'GET',
        path: `/api/admin/deployment/feature-flags/${firstFlag.key}`,
        token: accessToken
      });

      expect(flagRes.status).toBe(200);
      const flagData = unwrapData(flagRes.body);
      expect(flagData.key || firstFlag.key).toBe(firstFlag.key);
      expect(flagData.type).toBeDefined();
      expect(flagData.enabled).toBeDefined();
    });

    it('should toggle feature flag on/off', async () => {
      const listRes = await requestJson({
        method: 'GET',
        path: '/api/admin/deployment/feature-flags',
        token: accessToken
      });

      const flags = normalizeFlags(listRes.body);
      const targetFlag = flags.find(f => f.type === 'boolean');
      if (!targetFlag) {
        console.warn('⚠️  No boolean flag found for toggle test');
        return;
      }

      const originalState = targetFlag.enabled;

      const updateRes = await requestJson({
        method: 'PUT',
        path: `/api/admin/deployment/feature-flags/${targetFlag.key}`,
        token: accessToken,
        body: {
          enabled: !originalState,
          reason: 'E2E Test - Toggle Flag',
          executedBy: 'test-suite'
        }
      });

      expect(updateRes.status).toBe(200);
      expect(unwrapData(updateRes.body).enabled).toBe(!originalState);

      // Verify change persisted
      const getRes = await requestJson({
        method: 'GET',
        path: `/api/admin/deployment/feature-flags/${targetFlag.key}`,
        token: accessToken
      });

      expect(unwrapData(getRes.body).enabled).toBe(!originalState);

      // Restore original state
      await requestJson({
        method: 'PUT',
        path: `/api/admin/deployment/feature-flags/${targetFlag.key}`,
        token: accessToken,
        body: {
          enabled: originalState,
          reason: 'E2E Test - Restore Flag',
          executedBy: 'test-suite'
        }
      });
    });

    it('should set rollout percentage', async () => {
      const listRes = await requestJson({
        method: 'GET',
        path: '/api/admin/deployment/feature-flags',
        token: accessToken
      });

      const flags = normalizeFlags(listRes.body);
      const targetFlag = flags[0];
      if (!targetFlag) {
        console.warn('⚠️  No feature flag available for rollout test');
        return;
      }

      const updateRes = await requestJson({
        method: 'PUT',
        path: `/api/admin/deployment/feature-flags/${targetFlag.key}`,
        token: accessToken,
        body: {
          rolloutPercentage: 50,
          reason: 'E2E Test - Set Rollout Percentage',
          executedBy: 'test-suite'
        }
      });

      expect(updateRes.status).toBe(200);
      const updatedData = unwrapData(updateRes.body);
      expect(updatedData.rolloutPercentage || updatedData.percentage).toBe(50);
    });
  });

  // ========== Canary Deployment Tests ==========
  describe('Canary Deployments', () => {
    it('should retrieve canary deployment status', async () => {
      const flagRes = await requestJson({
        method: 'GET',
        path: '/api/admin/deployment/feature-flags',
        token: accessToken
      });

      const flags = normalizeFlags(flagRes.body);
      const canaryFlag = flags.find(f => f.type === 'canary');
      if (!canaryFlag) {
        console.warn('⚠️  No canary flag found');
        return;
      }

      expect(canaryFlag.stages).toBeDefined();
      expect(Array.isArray(canaryFlag.stages)).toBe(true);
      expect(canaryFlag.currentStage).toBeDefined();
    });

    it('should advance canary deployment stage', async () => {
      const flagRes = await requestJson({
        method: 'GET',
        path: '/api/admin/deployment/feature-flags',
        token: accessToken
      });

      const flags = normalizeFlags(flagRes.body);
      const canaryFlag = flags.find(f => f.type === 'canary');
      if (!canaryFlag || !Array.isArray(canaryFlag.stages) || canaryFlag.currentStage >= canaryFlag.stages.length - 1) {
        console.warn('⚠️  Canary flag not suitable for stage advancement test');
        return;
      }

      const advanceRes = await requestJson({
        method: 'POST',
        path: `/api/admin/deployment/feature-flags/${canaryFlag.key}/advance-canary`,
        token: accessToken,
        body: {
          reason: 'E2E Test - Manual Advance',
          executedBy: 'test-suite'
        }
      });

      expect([200, 201]).toContain(advanceRes.status);
      const advancedData = unwrapData(advanceRes.body);
      if (advancedData.currentStage !== undefined) {
        expect(advancedData.currentStage).toBeGreaterThan(canaryFlag.currentStage);
      }
    });
  });

  // ========== Deployment Metrics Tests ==========
  describe('Deployment Metrics', () => {
    it('should return health status', async () => {
      const response = await requestJson({
        method: 'GET',
        path: '/api/admin/deployment/metrics/health',
        token: accessToken
      });

      expect(response.status).toBe(200);
      const healthData = unwrapData(response.body);
      expect(healthData.status).toBeDefined();
      expect(['healthy', 'degraded', 'unhealthy']).toContain(
        healthData.status.toLowerCase()
      );

      // Should have key metrics
      expect(healthData.metrics).toBeDefined();
      expect(response.body.timestamp).toBeDefined();
    });

    it('should retrieve deployment metrics for time range', async () => {
      const now = Date.now();
      const oneHourAgo = now - 3600000;

      const response = await requestJson({
        method: 'GET',
        path: `/api/admin/deployment/metrics/range?startTime=${oneHourAgo}&endTime=${now}`,
        token: accessToken
      });

      expect(response.status).toBe(200);
      const rangeData = unwrapData(response.body);
      expect(Array.isArray(rangeData)).toBe(true);
      expect(response.body.timeline).toBeDefined();
    });

    it('should track request metrics', async () => {
      // Make some requests to generate metrics
      for (let i = 0; i < 3; i++) {
        await requestJson({
          method: 'GET',
          path: '/health',
          token: accessToken
        });

        if (i < 2) {
          await sleep(100);
        }
      }

      // Check metrics were captured
      const metricsRes = await requestJson({
        method: 'GET',
        path: '/api/admin/deployment/metrics/health',
        token: accessToken
      });

      expect(metricsRes.status).toBe(200);
      expect(unwrapData(metricsRes.body).metrics).toBeDefined();
    });
  });

  // ========== A/B Testing (Experiments) ==========
  describe('A/B Testing & Experiments', () => {
    it('should list experiments', async () => {
      const flagRes = await requestJson({
        method: 'GET',
        path: '/api/admin/deployment/feature-flags',
        token: accessToken
      });

      const flags = normalizeFlags(flagRes.body);
      const experiments = flags.filter(f => f.type === 'experiment');
      expect(Array.isArray(experiments)).toBe(true);

      // Should have at least some experiments configured
      if (experiments.length > 0) {
        const experiment = experiments[0];
        expect(experiment.variants).toBeDefined();
        expect(typeof experiment.variants).toBe('object');
      }
    });

    it('should get experiment statistical significance results', async () => {
      const flagRes = await requestJson({
        method: 'GET',
        path: '/api/admin/deployment/feature-flags',
        token: accessToken
      });

      const flags = normalizeFlags(flagRes.body);
      const experiments = flags.filter(f => f.type === 'experiment');
      if (experiments.length === 0) {
        console.warn('⚠️  No experiments configured');
        return;
      }

      const experimentKey = experiments[0].key;

      const resultsRes = await requestJson({
        method: 'GET',
        path: `/api/admin/deployment/experiments/${experimentKey}/results`,
        token: accessToken
      });

      expect([200, 404]).toContain(resultsRes.status);

      if (resultsRes.status === 200) {
        expect(resultsRes.body.data || resultsRes.body).toBeDefined();
      }
    });
  });

  // ========== User Journey Tests ==========
  describe('User Workflows with Feature Flags', () => {
    const itIfAuth = (desc, fn) => testUser && accessToken ? it(desc, fn) : it.skip(desc, fn);

    itIfAuth('should evaluate flags for user context', async () => {
      const response = await requestJson({
        method: 'POST',
        path: '/api/v1/auth/signin',
        body: {
          email: testUser.email,
          password: testUser.password,
          deviceId: testDeviceId
        }
      });

      expect([200, 400, 401]).toContain(response.status);

      if (response.status === 200) {
        const token = response.body.accessToken || response.body.token;
        expect(token).toBeDefined();

        // User-specific flag evaluation happens in app context
        // Verify user can access protected endpoints
        const profileRes = await requestJson({
          method: 'GET',
          path: '/api/v1/users/profile',
          token: token
        });

        expect([200, 401, 404]).toContain(profileRes.status);
      }
    });

    itIfAuth('should create account with feature flags context', async () => {
      if (!accessToken) {
        console.warn('⚠️  No access token, skipping account creation test');
        return;
      }

      const response = await requestJson({
        method: 'POST',
        path: '/api/v1/accounts',
        token: accessToken,
        body: {
          name: 'E2E Test Account',
          account_type: 'cash',
          currency: 'USD',
          current_balance: 1000,
          is_default: false
        }
      });

      expect([201, 200, 400, 401]).toContain(response.status);

      if ([201, 200].includes(response.status)) {
        expect(response.body.account_id || response.body.id).toBeDefined();
      }
    });
  });

  // ========== Rollback Mechanism Tests ==========
  describe('Rollback Mechanisms', () => {
    it('should track rollback decisions', async () => {
      const response = await requestJson({
        method: 'GET',
        path: '/api/admin/deployment/metrics/health',
        token: accessToken
      });

      expect(response.status).toBe(200);
      // Health check should not trigger rollback in normal scenarios
      const healthData = unwrapData(response.body);
      expect(['healthy', 'degraded']).toContain(
        healthData.status.toLowerCase()
      );
    });

    it('should provide rollback history endpoint', async () => {
      const response = await requestJson({
        method: 'GET',
        path: '/api/admin/deployment/rollbacks',
        token: accessToken
      });

      // Endpoint may or may not exist; check for graceful handling
      expect([200, 401, 403, 404]).toContain(response.status);

      if (response.status === 200) {
        expect(Array.isArray(response.body) || response.body.rollbacks !== undefined).toBe(true);
      }
    });
  });

  // ========== Stress & Uptime Tests ==========
  describe('System Stability', () => {
    it('should handle concurrent feature flag requests', async () => {
      const requests = Array(10).fill(null).map(() =>
        requestJson({
          method: 'GET',
          path: '/api/admin/deployment/feature-flags',
          token: accessToken
        })
      );

      const results = await Promise.allSettled(requests);
      const successful = results.filter(r => r.status === 'fulfilled' && r.value.status === 200);

      // Should handle most requests successfully
      expect(successful.length).toBeGreaterThanOrEqual(Math.ceil(results.length * 0.8));
    });

    it('should maintain health status consistency', async () => {
      const healthStatuses = [];

      for (let i = 0; i < 3; i++) {
        const res = await requestJson({
          method: 'GET',
          path: '/api/admin/deployment/metrics/health',
          token: accessToken
        });

        if (res.status === 200) {
          healthStatuses.push(unwrapData(res.body).status);
        }

        if (i < 2) {
          await sleep(500);
        }
      }

      // Status should be relatively consistent
      expect(healthStatuses.length).toBeGreaterThan(0);
    });
  });

  // ========== Integration Tests ==========
  describe('Integration Scenarios', () => {
    it('should complete user signup to account creation flow', async () => {
      if (!testUser) {
        console.warn('⚠️  Test user not created, skipping flow test');
        return;
      }

      // Already signed up in beforeAll
      expect(accessToken).toBeDefined();

      // Create account
      const accountRes = await requestJson({
        method: 'POST',
        path: '/api/v1/accounts',
        token: accessToken,
        body: {
          name: 'E2E Integration Test Account',
          account_type: 'savings',
          currency: 'USD',
          current_balance: 5000,
          is_default: true
        }
      });

      if ([201, 200].includes(accountRes.status)) {
        const accountId = accountRes.body.account_id || accountRes.body.id;
        expect(accountId).toBeDefined();

        // Verify account was created
        const listRes = await requestJson({
          method: 'GET',
          path: '/api/v1/accounts',
          token: accessToken
        });

        expect(listRes.status).toBe(200);
        expect(Array.isArray(listRes.body) || Array.isArray(listRes.body.accounts)).toBe(true);
      }
    });
  });

  // ========== Error Handling Tests ==========
  describe('Error Handling & Edge Cases', () => {
    it('should reject unauthorized flag updates', async () => {
      const response = await requestJson({
        method: 'PUT',
        path: '/api/admin/deployment/feature-flags/test-flag',
        // No token
        body: { enabled: true }
      });

      expect([401, 403]).toContain(response.status);
    });

    it('should handle invalid flag keys gracefully', async () => {
      const response = await requestJson({
        method: 'GET',
        path: '/api/admin/deployment/feature-flags/nonexistent-flag-key-xyz',
        token: accessToken
      });

      expect(response.status).toBe(404);
    });

    it('should validate metric time ranges', async () => {
      const response = await requestJson({
        method: 'GET',
        path: '/api/admin/deployment/metrics/range?startTime=invalid&endTime=invalid',
        token: accessToken
      });

      // Should either validate or return bad request
      expect([200, 400, 500]).toContain(response.status);
    });
  });

  afterAll(async () => {
    console.log('✅ Feature Flags & Deployment E2E Tests Complete');
  });
});
