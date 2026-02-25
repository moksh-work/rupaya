/**
 * Database Migration: Create Feature Flags Table
 * 
 * Migration ID: 20240115_001_create_feature_flags.js
 */

exports.up = function(knex) {
  return knex.schema
    // Feature flags table
    .createTable('feature_flags', function(table) {
      table.increments('id').primary();
      table.string('key').unique().notNullable().index();
      table.string('type').notNullable(); // 'boolean', 'canary', 'experiment', 'config'
      
      // Full flag configuration stored as JSON
      table.jsonb('config').notNullable();
      
      // Metadata
      table.string('created_by').nullable();
      table.string('updated_by').nullable();
      table.timestamps(true, true); // created_at, updated_at
      
      // Index for faster lookups
      table.index('type');
      table.index('created_at');
    })
    
    // Feature flag audit log
    .createTable('feature_flags_audit', function(table) {
      table.increments('id').primary();
      table.string('flag_key').notNullable()
        .references('key')
        .inTable('feature_flags')
        .onDelete('CASCADE');
      
      table.string('action').notNullable(); // 'create', 'update', 'delete'
      table.jsonb('before_config').nullable();
      table.jsonb('after_config').nullable();
      table.string('changed_by').notNullable();
      table.text('reason').nullable();
      table.timestamp('created_at').defaultTo(knex.fn.now());
      
      // Index for audit trail
      table.index('flag_key');
      table.index('created_at');
    })
    
    // Canary deployment events log
    .createTable('canary_deployment_logs', function(table) {
      table.increments('id').primary();
      table.string('flag_key').notNullable()
        .references('key')
        .inTable('feature_flags')
        .onDelete('CASCADE');
      
      table.string('event_type').notNullable(); // 'stage_start', 'stage_end', 'rollback'
      table.string('stage_name').nullable();
      table.integer('stage_number').nullable();
      table.decimal('traffic_percentage', 5, 2).nullable();
      
      // Metrics at time of event
      table.decimal('error_rate', 5, 2).nullable();
      table.decimal('p99_response_time_ms', 10, 2).nullable();
      table.integer('avg_response_time_ms').nullable();
      
      // Event metadata
      table.string('triggered_by').nullable(); // 'auto' or user ID
      table.text('reason').nullable();
      table.string('deployment_version').nullable();
      
      table.timestamp('created_at').defaultTo(knex.fn.now());
      
      // Indexes
      table.index('flag_key');
      table.index('event_type');
      table.index('created_at');
    })
    
    // Experiment results
    .createTable('experiment_results', function(table) {
      table.increments('id').primary();
      table.string('experiment_key').notNullable()
        .references('key')
        .inTable('feature_flags')
        .onDelete('CASCADE');
      
      table.string('variant').notNullable(); // 'control', 'variant_a', etc
      table.string('user_id').nullable();
      table.string('session_id').nullable();
      
      // Outcome metrics
      table.decimal('conversion_value', 10, 2).nullable();
      table.boolean('converted').defaultTo(false);
      table.integer('response_time_ms').nullable();
      table.boolean('had_error').defaultTo(false);
      
      // Context
      table.string('experiment_stage').nullable();
      table.string('deployment_version').nullable();
      
      table.timestamp('created_at').defaultTo(knex.fn.now());
      
      // Indexes
      table.index('experiment_key');
      table.index('variant');
      table.index('user_id');
      table.index('session_id');
      table.index('created_at');
    })
    
    // Deployment health metrics
    .createTable('deployment_metrics', function(table) {
      table.increments('id').primary();
      table.string('metric_key').notNullable(); // 'error_rate', 'response_time', etc
      table.decimal('metric_value', 10, 2).notNullable();
      
      // Segmentation
      table.string('segment_type').nullable(); // 'flag', 'endpoint', 'canary_stage', 'experiment'
      table.string('segment_value').nullable(); // The actual value
      table.string('deployment_version').nullable();
      
      // Time window
      table.timestamp('window_start').notNullable();
      table.timestamp('window_end').notNullable();
      table.integer('sample_count').defaultTo(0);
      
      table.timestamp('created_at').defaultTo(knex.fn.now());
      
      // Indexes
      table.index('metric_key');
      table.index(['segment_type', 'segment_value']);
      table.index('window_start');
      table.index(['window_start', 'window_end']);
    })
    
    // Rollback decision log
    .createTable('rollback_decisions', function(table) {
      table.increments('id').primary();
      table.string('deployment_version').notNullable();
      table.string('flag_key').nullable()
        .references('key')
        .inTable('feature_flags')
        .onDelete('SET NULL');
      
      table.string('decision').notNullable(); // 'rollback', 'continue', 'pause'
      table.string('reason').notNullable();
      table.jsonb('metrics_at_decision').notNullable();
      
      // Who decided
      table.string('decided_by').nullable(); // 'auto' or user ID
      table.boolean('was_manual').defaultTo(false);
      table.text('manual_notes').nullable();
      
      // Action taken
      table.string('action_taken').nullable(); // 'rollback_to_previous', 'pause_rollout', etc
      table.timestamp('action_completed_at').nullable();
      
      table.timestamp('created_at').defaultTo(knex.fn.now());
      
      // Indexes
      table.index('deployment_version');
      table.index('flag_key');
      table.index('created_at');
    });
};

exports.down = function(knex) {
  return knex.schema
    .dropTableIfExists('rollback_decisions')
    .dropTableIfExists('deployment_metrics')
    .dropTableIfExists('experiment_results')
    .dropTableIfExists('canary_deployment_logs')
    .dropTableIfExists('feature_flags_audit')
    .dropTableIfExists('feature_flags');
};
