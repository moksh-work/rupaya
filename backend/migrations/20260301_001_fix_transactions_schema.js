exports.up = async function up(knex) {
  const hasTransactionsTable = await knex.schema.hasTable('transactions');
  if (!hasTransactionsTable) {
    return;
  }

  const addColumnIfMissing = async (column, builder) => {
    const exists = await knex.schema.hasColumn('transactions', column);
    if (!exists) {
      await knex.schema.alterTable('transactions', table => {
        builder(table);
      });
    }
  };

  await addColumnIfMissing('account_id', table => {
    table.uuid('account_id').references('account_id').inTable('accounts');
  });

  await addColumnIfMissing('to_account_id', table => {
    table.uuid('to_account_id').references('account_id').inTable('accounts');
  });

  await addColumnIfMissing('amount', table => {
    table.decimal('amount', 15, 2);
  });

  await addColumnIfMissing('currency', table => {
    table.string('currency', 3).defaultTo('INR');
  });

  await addColumnIfMissing('transaction_type', table => {
    table.string('transaction_type', 20);
  });

  await addColumnIfMissing('category_id', table => {
    table.uuid('category_id').references('category_id').inTable('categories');
  });

  await addColumnIfMissing('description', table => {
    table.text('description');
  });

  await addColumnIfMissing('notes', table => {
    table.text('notes');
  });

  await addColumnIfMissing('location', table => {
    table.string('location', 255);
  });

  await addColumnIfMissing('merchant', table => {
    table.string('merchant', 255);
  });

  await addColumnIfMissing('tags', table => {
    table.specificType('tags', 'text[]');
  });

  await addColumnIfMissing('attachment_url', table => {
    table.string('attachment_url', 500);
  });

  await addColumnIfMissing('transaction_date', table => {
    table.date('transaction_date');
  });

  await addColumnIfMissing('updated_at', table => {
    table.timestamp('updated_at', { useTz: true }).defaultTo(knex.fn.now());
  });

  await addColumnIfMissing('is_deleted', table => {
    table.boolean('is_deleted').notNullable().defaultTo(false);
  });

  await knex.raw(`
    DO $$
    BEGIN
      IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'transactions_amount_positive_check'
      ) THEN
        ALTER TABLE transactions
        ADD CONSTRAINT transactions_amount_positive_check CHECK (amount > 0);
      END IF;
    END $$;
  `);

  await knex.raw(`
    DO $$
    BEGIN
      IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'transactions_type_check'
      ) THEN
        ALTER TABLE transactions
        ADD CONSTRAINT transactions_type_check CHECK (transaction_type IN ('income', 'expense', 'transfer'));
      END IF;
    END $$;
  `);

  await knex.raw('CREATE INDEX IF NOT EXISTS idx_transactions_account_id ON transactions(account_id);');
  await knex.raw('CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(user_id, transaction_date DESC);');
  await knex.raw('CREATE INDEX IF NOT EXISTS idx_transactions_type ON transactions(transaction_type);');
  await knex.raw('CREATE INDEX IF NOT EXISTS idx_transactions_category ON transactions(category_id);');
};

exports.down = async function down(knex) {
  await knex.raw('DROP INDEX IF EXISTS idx_transactions_account_id;');
  await knex.raw('DROP INDEX IF EXISTS idx_transactions_date;');
  await knex.raw('DROP INDEX IF EXISTS idx_transactions_type;');
  await knex.raw('DROP INDEX IF EXISTS idx_transactions_category;');
  await knex.raw('ALTER TABLE transactions DROP CONSTRAINT IF EXISTS transactions_amount_positive_check;');
  await knex.raw('ALTER TABLE transactions DROP CONSTRAINT IF EXISTS transactions_type_check;');
};
