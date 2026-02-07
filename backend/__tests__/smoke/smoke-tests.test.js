/**
 * Smoke Tests for Core API Endpoints
 * Quick validation that critical paths are working
 */

const request = require('supertest');
const app = require('../../src/app');

const describeSmoke = process.env.RUN_SMOKE_TESTS === 'true' ? describe : describe.skip;

describeSmoke('Smoke Tests - Core API Functionality', () => {
  let authToken;
  let userId;

  beforeAll(async () => {
    // Setup: Create and authenticate a test user
    const signupRes = await request(app)
      .post('/api/v1/auth/signup')
      .send({
        email: `smoke-test-${Date.now()}@example.com`,
        password: 'SmokeTest123!@#',
        deviceId: `smoke-device-${Date.now()}`,
        deviceName: 'smoke-device',
        firstName: 'Smoke',
        lastName: 'Test'
      });

    authToken = signupRes.body.token;
    userId = signupRes.body.user.id;
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
    it('should complete full auth cycle', async () => {
      // 1. Signup
      const signupRes = await request(app)
        .post('/api/auth/signup')
        .send({
          email: `smoke-auth-${Date.now()}@example.com`,
          password: 'SmokeTest123!@#',
          firstName: 'Test'
        });

      expect(signupRes.status).toBe(201);
      const token = signupRes.body.token;

      // 2. Use token to access protected route
      const profileRes = await request(app)
        .get('/api/user/profile')
        .set('Authorization', `Bearer ${token}`);

      expect(profileRes.status).toBe(200);

      // 3. Logout
      const logoutRes = await request(app)
        .post('/api/auth/logout')
        .set('Authorization', `Bearer ${token}`);

      expect(logoutRes.status).toBe(200);
    });
  });

  describe('Dashboard Endpoint', () => {
    it('should return dashboard data', async () => {
      const response = await request(app)
        .get('/api/dashboard')
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(response.body.balance).toBeDefined();
      expect(response.body.transactions).toBeDefined();
    });

    it('should return correct data structure', async () => {
      const response = await request(app)
        .get('/api/dashboard')
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.body).toHaveProperty('balance');
      expect(response.body).toHaveProperty('income');
      expect(response.body).toHaveProperty('expenses');
      expect(response.body).toHaveProperty('transactions');
      expect(response.body).toHaveProperty('categories');
    });
  });

  describe('Transactions Endpoint', () => {
    it('should create transaction', async () => {
      const response = await request(app)
        .post('/api/transactions')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          description: 'Smoke test transaction',
          amount: 100,
          category: 'Food',
          type: 'expense',
          date: new Date().toISOString()
        });

      expect(response.status).toBe(201);
      expect(response.body.id).toBeDefined();
    });

    it('should list transactions', async () => {
      const response = await request(app)
        .get('/api/transactions')
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(Array.isArray(response.body.data)).toBe(true);
    });

    it('should filter transactions by category', async () => {
      const response = await request(app)
        .get('/api/transactions?category=Food')
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(Array.isArray(response.body.data)).toBe(true);
    });
  });

  describe('Accounts Endpoint', () => {
    it('should create account', async () => {
      const response = await request(app)
        .post('/api/accounts')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          name: 'Test Checking',
          type: 'checking',
          balance: 1000,
          currency: 'USD'
        });

      expect(response.status).toBe(201);
      expect(response.body.id).toBeDefined();
    });

    it('should list accounts', async () => {
      const response = await request(app)
        .get('/api/accounts')
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(Array.isArray(response.body.data)).toBe(true);
    });
  });

  describe('Categories Endpoint', () => {
    it('should list categories', async () => {
      const response = await request(app)
        .get('/api/categories')
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(Array.isArray(response.body.data)).toBe(true);
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
      const response = await request(app)
        .get('/api/dashboard');

      expect(response.status).toBe(401);
    });

    it('should return 400 for invalid input', async () => {
      const response = await request(app)
        .post('/api/transactions')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          amount: -100, // Invalid: negative amount
          category: 'Food'
        });

      expect(response.status).toBe(400);
    });
  });

  describe('Response Format', () => {
    it('should include proper headers', async () => {
      const response = await request(app)
        .get('/api/dashboard')
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.headers['content-type']).toContain('json');
    });

    it('should include request ID', async () => {
      const response = await request(app)
        .get('/api/dashboard')
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.body.requestId).toBeDefined();
    });
  });
});
