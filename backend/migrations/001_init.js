// 001_init.js - Initial schema migration using Knex schema builder

exports.up = async function(knex) {
  // Users Table
  await knex.schema.createTable('users', table => {
    table.uuid('user_id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.string('email', 255).unique().notNullable();
    table.boolean('email_verified').defaultTo(false);
    table.string('password_hash', 255);
    table.string('name', 255);
    table.string('country_code', 2).defaultTo('IN');
    table.string('currency_preference', 3).defaultTo('INR');
    table.string('timezone', 50).defaultTo('Asia/Kolkata');
    table.string('theme_preference', 20).defaultTo('system');
    table.string('language_preference', 10).defaultTo('en');
    table.string('oauth_provider', 20);
    table.string('oauth_provider_id', 255);
    table.boolean('mfa_enabled').defaultTo(false);
    table.string('mfa_secret', 255);
    table.string('account_status', 20).defaultTo('active');
    table.timestamp('last_login_at', { useTz: true });
    table.string('last_login_device_id', 255);
    table.integer('login_attempt_count').defaultTo(0);
    table.timestamp('login_attempt_last_at', { useTz: true });
    table.timestamp('created_at', { useTz: true }).defaultTo(knex.fn.now());
    table.timestamp('updated_at', { useTz: true }).defaultTo(knex.fn.now());
    table.timestamp('deleted_at', { useTz: true });
    // No direct CHECK constraint for email regex in Knex; add via raw if needed
  });
  await knex.schema.raw("CREATE INDEX idx_users_email ON users(email)");
  await knex.schema.raw("CREATE INDEX idx_users_created_at ON users(created_at)");
  await knex.schema.raw("CREATE INDEX idx_users_status ON users(account_status)");

  // Devices Table
  await knex.schema.createTable('devices', table => {
    table.uuid('device_id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.uuid('user_id').notNullable().references('user_id').inTable('users').onDelete('CASCADE');
    table.string('device_name', 255);
    table.string('device_type', 20);
    table.string('device_fingerprint', 255).unique();
    table.boolean('is_active').defaultTo(true);
    table.timestamp('last_used_at', { useTz: true }).defaultTo(knex.fn.now());
    table.timestamp('created_at', { useTz: true }).defaultTo(knex.fn.now());
  });
  await knex.schema.raw("CREATE INDEX idx_devices_user_id ON devices(user_id)");
  await knex.schema.raw("CREATE INDEX idx_devices_fingerprint ON devices(device_fingerprint)");

  // Accounts Table
  await knex.schema.createTable('accounts', table => {
    table.uuid('account_id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.uuid('user_id').notNullable().references('user_id').inTable('users').onDelete('CASCADE');
    table.string('name', 255).notNullable();
    table.string('account_type', 20).notNullable();
    table.string('currency', 3).defaultTo('INR');
    table.decimal('current_balance', 15, 2).defaultTo(0);
    table.boolean('is_default').defaultTo(false);
    table.string('icon', 50);
    table.string('color', 7);
    table.timestamp('created_at', { useTz: true }).defaultTo(knex.fn.now());
    table.timestamp('updated_at', { useTz: true }).defaultTo(knex.fn.now());
    // No direct CHECK constraint for account_type in Knex; add via raw if needed
  });
  await knex.schema.raw("CREATE INDEX idx_accounts_user_id ON accounts(user_id)");
  await knex.schema.raw("CREATE INDEX idx_accounts_type ON accounts(account_type)");

  // Categories Table
  await knex.schema.createTable('categories', table => {
    table.uuid('category_id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.uuid('user_id').references('user_id').inTable('users').onDelete('CASCADE');
    table.string('name', 100).notNullable();
    table.string('category_type', 20).notNullable();
    table.string('icon', 50);
    table.string('color', 7);
    table.boolean('is_system').defaultTo(false);
    table.timestamp('created_at', { useTz: true }).defaultTo(knex.fn.now());
    // No direct CHECK constraint for category_type in Knex; add via raw if needed
  });
  await knex.schema.raw("CREATE INDEX idx_categories_user_id ON categories(user_id)");
  await knex.schema.raw("CREATE INDEX idx_categories_type ON categories(category_type)");

  // Transactions Table (partial, add more fields as needed)
  await knex.schema.createTable('transactions', table => {
    table.uuid('transaction_id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.uuid('user_id').notNullable().references('user_id').inTable('users').onDelete('CASCADE');
    // ... add other fields as in your SQL ...
    table.timestamp('created_at', { useTz: true }).defaultTo(knex.fn.now());
  });

  // Add more tables and constraints as needed, following the above pattern.
};

exports.down = async function(knex) {
  await knex.schema.dropTableIfExists('transactions');
  await knex.schema.dropTableIfExists('categories');
  await knex.schema.dropTableIfExists('accounts');
  await knex.schema.dropTableIfExists('devices');
  await knex.schema.dropTableIfExists('users');
};
