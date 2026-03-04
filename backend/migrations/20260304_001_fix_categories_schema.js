exports.up = async function(knex) {
  const hasCategoriesTable = await knex.schema.hasTable('categories');
  if (!hasCategoriesTable) return;

  const hasDescription = await knex.schema.hasColumn('categories', 'description');
  if (!hasDescription) {
    await knex.schema.alterTable('categories', table => {
      table.string('description', 200).nullable();
    });
  }

  const hasIsActive = await knex.schema.hasColumn('categories', 'is_active');
  if (!hasIsActive) {
    await knex.schema.alterTable('categories', table => {
      table.boolean('is_active').notNullable().defaultTo(true);
    });
  }

  const hasIsDeleted = await knex.schema.hasColumn('categories', 'is_deleted');
  if (!hasIsDeleted) {
    await knex.schema.alterTable('categories', table => {
      table.boolean('is_deleted').notNullable().defaultTo(false);
    });
  }

  const hasUpdatedAt = await knex.schema.hasColumn('categories', 'updated_at');
  if (!hasUpdatedAt) {
    await knex.schema.alterTable('categories', table => {
      table.timestamp('updated_at', { useTz: true }).defaultTo(knex.fn.now());
    });
  }
};

exports.down = async function(knex) {
  const hasCategoriesTable = await knex.schema.hasTable('categories');
  if (!hasCategoriesTable) return;

  const hasDescription = await knex.schema.hasColumn('categories', 'description');
  if (hasDescription) {
    await knex.schema.alterTable('categories', table => {
      table.dropColumn('description');
    });
  }

  const hasIsActive = await knex.schema.hasColumn('categories', 'is_active');
  if (hasIsActive) {
    await knex.schema.alterTable('categories', table => {
      table.dropColumn('is_active');
    });
  }

  const hasIsDeleted = await knex.schema.hasColumn('categories', 'is_deleted');
  if (hasIsDeleted) {
    await knex.schema.alterTable('categories', table => {
      table.dropColumn('is_deleted');
    });
  }

  const hasUpdatedAt = await knex.schema.hasColumn('categories', 'updated_at');
  if (hasUpdatedAt) {
    await knex.schema.alterTable('categories', table => {
      table.dropColumn('updated_at');
    });
  }
};
