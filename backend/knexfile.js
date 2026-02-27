// Knexfile for database migrations
require('dotenv').config();

const dbSslEnabled = process.env.DB_SSL === 'true' || process.env.NODE_ENV === 'production';

function buildConnection(defaultHost) {
  if (process.env.DATABASE_URL) {
    return {
      connectionString: process.env.DATABASE_URL,
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
