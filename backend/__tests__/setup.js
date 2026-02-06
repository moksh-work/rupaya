/**
 * Jest Setup File
 * Runs before all tests
 */

// Set test environment variables
process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test-secret-key';
process.env.DATABASE_URL = 'postgres://test_user:test_password@localhost:5432/rupaya_test';
process.env.REDIS_URL = 'redis://localhost:6379';

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

// Mock external services
jest.mock('aws-sdk');
jest.mock('redis');
