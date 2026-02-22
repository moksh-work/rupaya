const knex = require('knex');
require('dotenv').config();

// Build connection configuration
const useSSL = (process.env.DB_SSL === 'true' || process.env.NODE_ENV === 'production');

const connectionConfig = {
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432'),
  user: process.env.DB_USER || 'rupaya',
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME || 'rupaya_dev'
};

// Add SSL configuration if needed (required for RDS PostgreSQL 18)
if (useSSL) {
  connectionConfig.ssl = { rejectUnauthorized: false };
}

const config = {
  client: 'pg',
  connection: process.env.DATABASE_URL || connectionConfig,
  pool: { min: 2, max: 10 },
  migrations: { directory: './migrations' },
  seeds: { directory: './seeds' }
};

module.exports = knex(config);
