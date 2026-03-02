// 002_add_phone_number_to_users.js - Add phone_number column to users table

exports.up = async function(knex) {
  const hasUsersTable = await knex.schema.hasTable('users');
  if (!hasUsersTable) {
    return;
  }

  const hasPhoneNumber = await knex.schema.hasColumn('users', 'phone_number');
  const hasPhoneVerified = await knex.schema.hasColumn('users', 'phone_verified');

  if (!hasPhoneNumber || !hasPhoneVerified) {
    await knex.schema.alterTable('users', table => {
      if (!hasPhoneNumber) {
        table.string('phone_number', 20).unique().nullable();
      }
      if (!hasPhoneVerified) {
        table.boolean('phone_verified').defaultTo(false);
      }
    });
  }

  await knex.schema.raw('CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone_number)');
};

exports.down = async function(knex) {
  const hasUsersTable = await knex.schema.hasTable('users');
  if (!hasUsersTable) {
    return;
  }

  const hasPhoneNumber = await knex.schema.hasColumn('users', 'phone_number');
  const hasPhoneVerified = await knex.schema.hasColumn('users', 'phone_verified');

  if (hasPhoneNumber || hasPhoneVerified) {
    await knex.schema.alterTable('users', table => {
      if (hasPhoneNumber) {
        table.dropColumn('phone_number');
      }
      if (hasPhoneVerified) {
        table.dropColumn('phone_verified');
      }
    });
  }
};
