/**
 * Feature Flags Configuration
 * 
 * This module manages runtime feature flags for Rupaya backend.
 * Supports:
 *   - Boolean flags (enable/disable features)
 *   - Percentage-based rollout (gradual canary deployments)
 *   - User-based targeting
 *   - Environment-specific overrides
 * 
 * Storage: PostgreSQL with Redis cache (TTL: 5 minutes)
 * Priority: Environment Variables > Database > Defaults
 */

const defaultFlags = {
  // Core feature flags
  'feature.new-dashboard': {
    enabled: false,
    type: 'boolean',
    description: 'Enable new dashboard UI',
    percentage: 0,
    targetUsers: [],
    environments: {
      development: { enabled: true, percentage: 100 },
      staging: { enabled: true, percentage: 50 },
      production: { enabled: false, percentage: 0 }
    },
    createdAt: new Date('2024-01-01'),
    updatedAt: new Date('2024-01-01')
  },

  'feature.advanced-analytics': {
    enabled: false,
    type: 'boolean',
    description: 'Enable advanced analytics features',
    percentage: 0,
    targetUsers: [],
    environments: {
      development: { enabled: true, percentage: 100 },
      staging: { enabled: true, percentage: 25 },
      production: { enabled: false, percentage: 0 }
    },
    createdAt: new Date('2024-01-01'),
    updatedAt: new Date('2024-01-01')
  },

  'feature.ai-budgeting': {
    enabled: false,
    type: 'boolean',
    description: 'Enable AI-powered budget recommendations',
    percentage: 0,
    targetUsers: [],
    environments: {
      development: { enabled: true, percentage: 100 },
      staging: { enabled: false, percentage: 0 },
      production: { enabled: false, percentage: 0 }
    },
    createdAt: new Date('2024-01-01'),
    updatedAt: new Date('2024-01-01')
  },

  'feature.offline-sync': {
    enabled: false,
    type: 'boolean',
    description: 'Enable offline sync capability',
    percentage: 0,
    targetUsers: [],
    environments: {
      development: { enabled: true, percentage: 100 },
      staging: { enabled: false, percentage: 0 },
      production: { enabled: false, percentage: 0 }
    },
    createdAt: new Date('2024-01-01'),
    updatedAt: new Date('2024-01-01')
  },

  // Canary deployment flags
  'canary.new-payment-processor': {
    enabled: false,
    type: 'canary',
    description: 'Gradual rollout of new payment processor',
    percentage: 0,
    targetUsers: [],
    environments: {
      development: { enabled: true, percentage: 100 },
      staging: { enabled: true, percentage: 100 },
      production: { enabled: false, percentage: 0 }
    },
    stages: [
      { name: '1%', percentage: 1, durationMinutes: 30 },
      { name: '10%', percentage: 10, durationMinutes: 30 },
      { name: '25%', percentage: 25, durationMinutes: 60 },
      { name: '50%', percentage: 50, durationMinutes: 60 },
      { name: '100%', percentage: 100, durationMinutes: 0 }
    ],
    currentStage: 0,
    stageStartedAt: null,
    createdAt: new Date('2024-01-01'),
    updatedAt: new Date('2024-01-01')
  },

  'canary.new-notification-service': {
    enabled: false,
    type: 'canary',
    description: 'Gradual rollout of new notification service',
    percentage: 0,
    targetUsers: [],
    environments: {
      development: { enabled: true, percentage: 100 },
      staging: { enabled: false, percentage: 0 },
      production: { enabled: false, percentage: 0 }
    },
    stages: [
      { name: '5%', percentage: 5, durationMinutes: 30 },
      { name: '25%', percentage: 25, durationMinutes: 30 },
      { name: '100%', percentage: 100, durationMinutes: 0 }
    ],
    currentStage: 0,
    stageStartedAt: null,
    createdAt: new Date('2024-01-01'),
    updatedAt: new Date('2024-01-01')
  },

  // A/B testing flags
  'experiment.new-onboarding-flow': {
    enabled: false,
    type: 'experiment',
    description: 'A/B test new user onboarding flow',
    percentage: 0,
    variants: {
      control: { percentage: 50, description: 'Original onboarding' },
      variant_a: { percentage: 50, description: 'New simplified flow' }
    },
    targetUsers: [],
    environments: {
      development: { enabled: true, percentage: 100 },
      staging: { enabled: true, percentage: 50 },
      production: { enabled: false, percentage: 0 }
    },
    createdAt: new Date('2024-01-01'),
    updatedAt: new Date('2024-01-01')
  },

  'experiment.checkout-redesign': {
    enabled: false,
    type: 'experiment',
    description: 'A/B test checkout page redesign',
    percentage: 0,
    variants: {
      control: { percentage: 50, description: 'Original checkout' },
      variant_a: { percentage: 50, description: 'Redesigned checkout' }
    },
    targetUsers: [],
    environments: {
      development: { enabled: true, percentage: 100 },
      staging: { enabled: false, percentage: 0 },
      production: { enabled: false, percentage: 0 }
    },
    createdAt: new Date('2024-01-01'),
    updatedAt: new Date('2024-01-01')
  },

  // Rollback safeguard flags
  'rollback.circuit-breaker-enabled': {
    enabled: true,
    type: 'boolean',
    description: 'Enable circuit breaker for automatic rollback protection',
    percentage: 100,
    targetUsers: [],
    environments: {
      development: { enabled: true, percentage: 100 },
      staging: { enabled: true, percentage: 100 },
      production: { enabled: true, percentage: 100 }
    },
    createdAt: new Date('2024-01-01'),
    updatedAt: new Date('2024-01-01')
  },

  'rollback.error-rate-threshold': {
    enabled: true,
    type: 'config',
    description: 'Error rate threshold (%) for triggering rollback',
    value: 5,
    targetUsers: [],
    environments: {
      development: { value: 10 },
      staging: { value: 7 },
      production: { value: 5 }
    },
    createdAt: new Date('2024-01-01'),
    updatedAt: new Date('2024-01-01')
  },

  'rollback.response-time-threshold': {
    enabled: true,
    type: 'config',
    description: 'Response time threshold (ms) for triggering rollback',
    value: 2000,
    targetUsers: [],
    environments: {
      development: { value: 5000 },
      staging: { value: 3000 },
      production: { value: 2000 }
    },
    createdAt: new Date('2024-01-01'),
    updatedAt: new Date('2024-01-01')
  }
};

module.exports = {
  defaultFlags,
  
  /**
   * Merge environment-specific overrides with defaults
   */
  getEnvironmentConfig(environment = process.env.NODE_ENV || 'development') {
    const config = JSON.parse(JSON.stringify(defaultFlags));
    
    Object.keys(config).forEach(flagKey => {
      const flag = config[flagKey];
      if (flag.environments && flag.environments[environment]) {
        const envOverride = flag.environments[environment];
        Object.assign(flag, envOverride);
      }
    });

    return config;
  },

  /**
   * Validate flag configuration schema
   */
  validateFlag(flag) {
    const required = ['enabled', 'type', 'description'];
    const validTypes = ['boolean', 'canary', 'experiment', 'config'];

    for (const field of required) {
      if (!(field in flag)) {
        throw new Error(`Missing required field: ${field}`);
      }
    }

    if (!validTypes.includes(flag.type)) {
      throw new Error(`Invalid flag type: ${flag.type}`);
    }

    if (flag.type === 'canary' && !flag.stages) {
      throw new Error('Canary flags must have stages defined');
    }

    if (flag.type === 'experiment' && !flag.variants) {
      throw new Error('Experiment flags must have variants defined');
    }

    return true;
  }
};
