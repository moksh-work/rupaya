const knex = require('knex');
require('dotenv').config();

function inferSslFromDatabaseUrl(databaseUrl) {
  if (!databaseUrl) {
    return false;
  }

  try {
    const parsedUrl = new URL(databaseUrl);
    const host = (parsedUrl.hostname || '').toLowerCase();
    return host !== 'localhost' && host !== '127.0.0.1' && host !== 'postgres';
  } catch (error) {
    return true;
  }
}

function isSslEnabled() {
  if (process.env.DB_SSL === 'true') {
    return true;
  }

  if (process.env.DB_SSL === 'false') {
    return false;
  }

  if (process.env.NODE_ENV === 'production') {
    return true;
  }

  return inferSslFromDatabaseUrl(process.env.DATABASE_URL);
}

// Build connection configuration
const useSSL = isSslEnabled();

function sanitizeDatabaseUrl(databaseUrl) {
  try {
    const parsedUrl = new URL(databaseUrl);
    parsedUrl.searchParams.delete('sslmode');
    parsedUrl.searchParams.delete('sslrootcert');
    parsedUrl.searchParams.delete('sslcert');
    parsedUrl.searchParams.delete('sslkey');
    return parsedUrl.toString();
  } catch (error) {
    return databaseUrl;
  }
}

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

const connection = process.env.DATABASE_URL
  ? {
      connectionString: sanitizeDatabaseUrl(process.env.DATABASE_URL),
      ssl: useSSL ? { rejectUnauthorized: false } : false
    }
  : connectionConfig;

const config = {
  client: 'pg',
  connection,
  pool: { min: 2, max: 10 },
  migrations: { directory: './migrations' },
  seeds: { directory: './seeds' }
};

module.exports = knex(config);
