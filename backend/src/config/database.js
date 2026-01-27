const knex = require('knex');
require('dotenv').config();

const config = {
  client: 'pg',
  connection: {
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 5432,
    user: process.env.DB_USER || 'rupaya',
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME || 'rupaya_dev',
    ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
  },
  pool: { min: 2, max: 10 },
  migrations: { directory: './migrations' },
  seeds: { directory: './seeds' }
};

module.exports = knex(config);
