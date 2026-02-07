const request = require('supertest');
const app = require('../src/app');

const describeApi = process.env.RUN_API_TESTS === 'true' ? describe : describe.skip;

describeApi('Authentication API', () => {
  it('should fail signin with invalid credentials', async () => {
    const res = await request(app)
      .post('/api/v1/auth/signin')
      .send({ email: 'invalid@example.com', password: 'wrongpass', deviceId: 'test' });
    expect([401, 400]).toContain(res.statusCode); // Accept 401 or 400
    expect(res.body.error || res.body.message).toMatch(/invalid|not found|incorrect/i);
  });

  it('should sign up and signin successfully', async () => {
    const email = `test${Date.now()}@example.com`;
    const password = 'TestPass123!@#Longer';
    const deviceId = 'test';
    const deviceName = 'test-device';
    await request(app)
      .post('/api/v1/auth/signup')
      .send({ email, password, deviceId, deviceName })
      .expect(201);
    const res = await request(app)
      .post('/api/v1/auth/signin')
      .send({ email, password, deviceId });
    expect(res.statusCode).toBe(200);
    expect(res.body.accessToken || res.body.token).toBeDefined();
  });
});
