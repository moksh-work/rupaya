// 002_add_phone_number_to_users.js - Add phone_number column to users table

exports.up = async function(knex) {
  await knex.schema.alterTable('users', table => {
    table.string('phone_number', 20).unique().nullable();
    table.boolean('phone_verified').defaultTo(false);
  });
};

exports.down = async function(knex) {
  await knex.schema.alterTable('users', table => {
    table.dropColumn('phone_number');
    table.dropColumn('phone_verified');
  });
};
