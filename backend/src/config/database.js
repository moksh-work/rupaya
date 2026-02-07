const knex = require('knex');
require('dotenv').config();

const connection = process.env.DATABASE_URL
  ? process.env.DATABASE_URL
  : {
      host: process.env.DB_HOST || 'localhost',
      port: process.env.DB_PORT || 5432,
      user: process.env.DB_USER || 'rupaya',
      password: process.env.DB_PASSWORD,
      database: process.env.DB_NAME || 'rupaya_dev'
    };

const config = {
  client: 'pg',
  connection,
  pool: { min: 2, max: 10 },
  migrations: { directory: './migrations' },
  seeds: { directory: './seeds' },
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
};

module.exports = knex(config);
