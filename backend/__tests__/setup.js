/**
 * Jest Setup File
 * Runs before all tests
 */

// Set test environment variables
process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test-secret-key';
process.env.REFRESH_TOKEN_SECRET = 'test-refresh-secret';
process.env.DATABASE_URL = 'postgres://test_user:test_password@127.0.0.1:5432/rupaya_test';
process.env.REDIS_URL = 'redis://localhost:6379';
process.env.DISABLE_TOKEN_CLEANUP = 'true';
process.env.DISABLE_PASSWORD_STRENGTH = 'true';
process.env.DISABLE_PWNED_CHECK = 'true';

// Suppress console logs during tests (optional)
// global.console = {
//   ...console,
//   log: jest.fn(),
//   debug: jest.fn(),
//   info: jest.fn(),
//   warn: jest.fn(),
// };

// Set timeout for all tests
jest.setTimeout(30000);

const db = require('../src/config/database');

beforeAll(async () => {
	await db.migrate.latest();
});

afterAll(async () => {
	await db.destroy();
});

// Mock external services
jest.mock('aws-sdk');
jest.mock('redis');
