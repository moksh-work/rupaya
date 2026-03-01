exports.up = async function(knex) {
  const exists = await knex.schema.hasTable('revoked_tokens');

  if (!exists) {
    await knex.schema.createTable('revoked_tokens', table => {
      table.uuid('token_id').primary();
      table.uuid('user_id').notNullable().references('user_id').inTable('users').onDelete('CASCADE');
      table.string('token_type', 20).notNullable().defaultTo('refresh');
      table.timestamp('expires_at', { useTz: true }).notNullable();
      table.timestamp('created_at', { useTz: true }).defaultTo(knex.fn.now());
    });

    await knex.schema.raw('CREATE INDEX IF NOT EXISTS idx_revoked_tokens_user_id ON revoked_tokens(user_id)');
    await knex.schema.raw('CREATE INDEX IF NOT EXISTS idx_revoked_tokens_expires_at ON revoked_tokens(expires_at)');
  }
};

exports.down = async function(knex) {
  const exists = await knex.schema.hasTable('revoked_tokens');

  if (exists) {
    await knex.schema.dropTable('revoked_tokens');
  }
};
