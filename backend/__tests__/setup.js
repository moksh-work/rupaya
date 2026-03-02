/**
 * Jest Setup File
 * Runs before all tests
 */

// Set test environment variables
process.env.NODE_ENV = process.env.NODE_ENV || 'test';
process.env.JWT_SECRET = process.env.JWT_SECRET || 'test-secret-key';
process.env.REFRESH_TOKEN_SECRET = process.env.REFRESH_TOKEN_SECRET || 'test-refresh-secret';
process.env.DATABASE_URL = process.env.DATABASE_URL || `postgres://${process.env.DB_USER || 'test_user'}:${process.env.DB_PASSWORD || 'test_password'}@${process.env.DB_HOST || '127.0.0.1'}:${process.env.DB_PORT || '5432'}/${process.env.DB_NAME || 'rupaya_test'}`;
process.env.REDIS_URL = process.env.REDIS_URL || `redis://${process.env.REDIS_HOST || 'localhost'}:${process.env.REDIS_PORT || '6379'}`;
process.env.DISABLE_TOKEN_CLEANUP = process.env.DISABLE_TOKEN_CLEANUP || 'true';
process.env.DISABLE_PASSWORD_STRENGTH = process.env.DISABLE_PASSWORD_STRENGTH || 'true';
process.env.DISABLE_PWNED_CHECK = process.env.DISABLE_PWNED_CHECK || 'true';

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
const shouldSkipDbHooks = process.env.RUN_E2E_TESTS === 'true' || process.env.RUN_REMOTE_TESTS === 'true';

beforeAll(async () => {
	if (shouldSkipDbHooks) {
		return;
	}
	await db.migrate.latest();
});

afterAll(async () => {
	await db.destroy();
});

// Mock external services
jest.mock('redis');
