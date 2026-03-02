/**
 * Smoke Tests for Core API Endpoints
 * Quick validation that critical paths are working with current API contracts.
 */

const request = require('supertest');
const app = require('../../src/app');

const describeSmoke = process.env.RUN_SMOKE_TESTS === 'true' ? describe : describe.skip;

describeSmoke('Smoke Tests - Core API Functionality', () => {
  let authToken;
  let accountId;

  beforeAll(async () => {
    const suffix = Date.now();

    const signupRes = await request(app)
      .post('/api/v1/auth/signup')
      .send({
        email: `smoke-test-${suffix}@example.com`,
        password: 'SmokeTest123!@#',
        deviceId: `smoke-device-${suffix}`,
        deviceName: 'smoke-device'
      });

    expect(signupRes.status).toBe(201);
    authToken = signupRes.body.accessToken || signupRes.body.token;
    expect(authToken).toBeDefined();

    const accountRes = await request(app)
      .post('/api/v1/accounts')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        name: 'Smoke Cash Account',
        account_type: 'cash',
        currency: 'USD',
        current_balance: 1000,
        is_default: false
      });

    expect(accountRes.status).toBe(201);
    accountId = accountRes.body.account_id || accountRes.body.accountId || accountRes.body.id;
    expect(accountId).toBeDefined();
  });

  describe('Health Endpoint', () => {
    it('should return OK status', async () => {
      const response = await request(app).get('/health');
      expect(response.status).toBe(200);
      expect(response.body.status).toBe('OK');
    });

    it('should include timestamp', async () => {
      const response = await request(app).get('/health');
      expect(response.body.timestamp).toBeDefined();
    });
  });

  describe('Authentication Flow', () => {
    it('should complete signin/logout flow', async () => {
      const suffix = Date.now();
      const email = `smoke-auth-${suffix}@example.com`;
      const password = 'SmokeTest123!@#';
      const deviceId = `smoke-auth-device-${suffix}`;

      const signupRes = await request(app)
        .post('/api/auth/signup')
        .send({ email, password, deviceId, deviceName: 'smoke-auth-device' });

      expect(signupRes.status).toBe(201);

      const signinRes = await request(app)
        .post('/api/auth/signin')
        .send({ email, password, deviceId });

      expect(signinRes.status).toBe(200);
      const token = signinRes.body.accessToken || signinRes.body.token;
      expect(token).toBeDefined();

      const profileRes = await request(app)
        .get('/api/user/profile')
        .set('Authorization', `Bearer ${token}`);

      expect(profileRes.status).toBe(200);

      const logoutRes = await request(app)
        .post('/api/auth/logout')
        .set('Authorization', `Bearer ${token}`)
        .send({});

      expect(logoutRes.status).toBe(200);
    });
  });

  describe('Analytics Endpoint', () => {
    it('should return dashboard analytics data', async () => {
      const response = await request(app)
        .get('/api/analytics/dashboard')
        .set('Authorization', `Bearer ${authToken}`);

      expect([200, 400]).toContain(response.status);
      if (response.status === 200) {
        expect(response.body).toBeDefined();
      }
    });
  });

  describe('Transactions Endpoint', () => {
    it('should create transaction', async () => {
      const response = await request(app)
        .post('/api/transactions')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          accountId,
          amount: 100,
          type: 'expense',
          description: 'Smoke test transaction',
          date: new Date().toISOString()
        });

      expect(response.status).toBe(201);
      expect(response.body.transaction_id || response.body.id).toBeDefined();
    });

    it('should list transactions', async () => {
      const response = await request(app)
        .get('/api/transactions')
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(Array.isArray(response.body)).toBe(true);
    });
  });

  describe('Accounts Endpoint', () => {
    it('should list accounts', async () => {
      const response = await request(app)
        .get('/api/accounts')
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(Array.isArray(response.body)).toBe(true);
    });
  });

  describe('Error Handling', () => {
    it('should return 404 for non-existent endpoint', async () => {
      const response = await request(app)
        .get('/api/non-existent')
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(404);
    });

    it('should return 401 without authentication', async () => {
      const response = await request(app).get('/api/accounts');
      expect(response.status).toBe(401);
    });

    it('should return 400 for invalid input', async () => {
      const response = await request(app)
        .post('/api/transactions')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          amount: -100,
          type: 'expense'
        });

      expect(response.status).toBe(400);
    });
  });

  describe('Response Format', () => {
    it('should include JSON content type', async () => {
      const response = await request(app)
        .get('/api/accounts')
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.headers['content-type']).toContain('json');
    });
  });
});
