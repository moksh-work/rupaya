// Knexfile for database migrations
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

const dbSslEnabled = isSslEnabled();

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

function buildConnection(defaultHost) {
  if (process.env.DATABASE_URL) {
    return {
      connectionString: sanitizeDatabaseUrl(process.env.DATABASE_URL),
      ssl: dbSslEnabled ? { rejectUnauthorized: false } : false
    };
  }

  return {
    host: process.env.DB_HOST || defaultHost,
    port: process.env.DB_PORT || 5432,
    user: process.env.DB_USER || 'rupaya',
    password: process.env.DB_PASSWORD || 'secure_password_here',
    database: process.env.DB_NAME || 'rupaya_dev',
    ssl: dbSslEnabled ? { rejectUnauthorized: false } : false
  };
}

const developmentConnection = buildConnection('postgres');

const productionConnection = buildConnection(undefined);

module.exports = {
  development: {
    client: 'postgresql',
    connection: developmentConnection,
    pool: {
      min: 2,
      max: 10
    },
    migrations: {
      tableName: 'knex_migrations',
      directory: './migrations'
    }
  },

  test: {
    client: 'postgresql',
    connection: {
      host: process.env.DB_HOST || 'localhost',
      port: process.env.DB_PORT || 5432,
      user: process.env.DB_USER || 'test_user',
      password: process.env.DB_PASSWORD || 'test_password',
      database: process.env.DB_NAME || 'rupaya_test'
    },
    pool: {
      min: 1,
      max: 5
    },
    migrations: {
      tableName: 'knex_migrations',
      directory: './migrations'
    }
  },

  production: {
    client: 'postgresql',
    connection: productionConnection,
    pool: {
      min: 2,
      max: 20
    },
    migrations: {
      tableName: 'knex_migrations',
      directory: './migrations'
    }
  }
};
