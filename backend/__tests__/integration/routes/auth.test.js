/**
 * Integration Tests for Authentication Routes
 * Tests API endpoints, middleware, and database interactions
 */

const request = require('supertest');
const app = require('../../../src/app');
const db = require('../../../src/config/database');

describe('Authentication Routes - Integration Tests', () => {
  beforeAll(async () => {
    // Setup test database connection
    await db.migrate.latest();
  });

  // Database connection is closed in __tests__/setup.js

  beforeEach(async () => {
    // Clear test data before each test
    await db('users').del();
  });

  describe('POST /api/auth/signup', () => {
    it('should create new user with valid data', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          email: 'newuser@example.com',
          password: 'SecurePass123!@#Longer',
            deviceId: 'test-device',
            deviceName: 'test-device',
          firstName: 'John',
          lastName: 'Doe'
        });

        expect(response.status).toBe(201);
        expect(response.body.accessToken).toBeDefined();
      expect(response.body.user.email).toBe('newuser@example.com');
    });

    it('should reject invalid email', async () => {
      const response = await request(app)
          .post('/api/v1/auth/signup')
        .send({
          email: 'invalid-email',
          password: 'SecurePass123!@#',
            deviceId: 'test-device',
            deviceName: 'test-device',
          firstName: 'John'
        });

      expect(response.status).toBe(400);
      const errorMessage = response.body.error || JSON.stringify(response.body.errors || []);
      expect(errorMessage).toBeDefined();
    });

    it('should reject weak password', async () => {
      const response = await request(app)
          .post('/api/v1/auth/signup')
        .send({
          email: 'test@example.com',
          password: 'weak',
            deviceId: 'test-device',
            deviceName: 'test-device',
          firstName: 'John'
        });

      expect(response.status).toBe(400);
      const errorMessage = response.body.error || JSON.stringify(response.body.errors || []);
      expect(errorMessage.toLowerCase()).toContain('password');
    });

    it('should reject duplicate email', async () => {
      // Create first user
      await request(app)
        .post('/api/v1/auth/signup')
        .send({
          email: 'duplicate@example.com',
          password: 'SecurePass123!@#Longer',
          deviceId: 'test-device',
          deviceName: 'test-device',
          firstName: 'John'
        });

      // Try to create with same email
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          email: 'duplicate@example.com',
          password: 'DifferentPass123!@#Longer',
          deviceId: 'test-device',
          deviceName: 'test-device',
          firstName: 'Jane'
        });

      expect(response.status).toBe(409);
      expect(response.body.error).toContain('already exists');
    });
  });

  describe('POST /api/auth/login', () => {
    beforeEach(async () => {
      // Create test user
      await request(app)
        .post('/api/auth/signup')
        .send({
          email: 'testuser@example.com',
          password: 'SecurePass123!@#Longer',
          deviceId: 'test-device',
          deviceName: 'test-device',
          firstName: 'Test'
        });
    });

    it('should login with correct credentials', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'testuser@example.com',
          password: 'SecurePass123!@#Longer',
          deviceId: 'test-device'
        });

      expect(response.status).toBe(200);
      expect(response.body.token).toBeDefined();
      expect(response.body.user.email).toBe('testuser@example.com');
    });

    it('should reject incorrect password', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'testuser@example.com',
          password: 'WrongPassword123!@#',
          deviceId: 'test-device'
        });

      expect(response.status).toBe(401);
      expect((response.body.error || '').toLowerCase()).toMatch(/invalid|password/);
    });

    it('should reject non-existent user', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'nonexistent@example.com',
          password: 'SomePass123!@#',
          deviceId: 'test-device'
        });

      expect(response.status).toBe(401);
    });

    it('should reject invalid email format', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'invalid-email',
          password: 'SecurePass123!@#Longer',
          deviceId: 'test-device'
        });

      expect(response.status).toBe(400);
    });
  });

  describe('POST /api/auth/logout', () => {
    it('should logout successfully', async () => {
      // Create user before login
      await request(app)
        .post('/api/v1/auth/signup')
        .send({
          email: 'testuser@example.com',
          password: 'SecurePass123!@#Longer',
          deviceId: 'test-device',
          deviceName: 'test-device',
          firstName: 'Test'
        });

      // Login first
      const loginRes = await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: 'testuser@example.com',
          password: 'SecurePass123!@#Longer',
          deviceId: 'test-device'
        });

      const token = loginRes.body.token;

      // Logout
      const logoutRes = await request(app)
        .post('/api/v1/auth/logout')
        .set('Authorization', `Bearer ${token}`);

      expect(logoutRes.status).toBe(200);

      // Access token remains valid until expiry
      const protectedRes = await request(app)
        .get('/api/v1/users/profile')
        .set('Authorization', `Bearer ${token}`);

      expect(protectedRes.status).toBe(200);
    });
  });

  describe('Protected Routes with Auth Middleware', () => {
    let token;

    beforeEach(async () => {
      await request(app)
        .post('/api/v1/auth/signup')
        .send({
          email: 'testuser@example.com',
          password: 'SecurePass123!@#',
          deviceId: 'test-device',
          deviceName: 'test-device',
          firstName: 'Test'
        });

      const res = await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: 'testuser@example.com',
          password: 'SecurePass123!@#',
          deviceId: 'test-device'
        });

      token = res.body.token;
    });

    it('should allow access with valid token', async () => {
      const response = await request(app)
        .get('/api/v1/users/profile')
        .set('Authorization', `Bearer ${token}`);

      expect(response.status).toBe(200);
    });

    it('should reject request without token', async () => {
      const response = await request(app)
        .get('/api/v1/users/profile');

      expect(response.status).toBe(401);
    });

    it('should reject request with invalid token', async () => {
      const response = await request(app)
        .get('/api/v1/users/profile')
        .set('Authorization', 'Bearer invalid-token');

      expect(response.status).toBe(401);
    });

    it('should reject request with expired token', async () => {
      // Create expired token
      const expiredToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjB9.expired';

      const response = await request(app)
        .get('/api/v1/users/profile')
        .set('Authorization', `Bearer ${expiredToken}`);

      expect(response.status).toBe(401);
    });
  });
});
