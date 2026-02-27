const fs = require('fs');
const path = require('path');
const https = require('https');
const http = require('http');

const API_BASE_URL = process.env.API_BASE_URL || 'http://localhost:3000';
const shouldRunRemote = process.env.RUN_REMOTE_TESTS === 'true';

const describeRemote = shouldRunRemote ? describe : describe.skip;

const requestJson = ({ method, requestPath, token, body }) => {
  return new Promise((resolve, reject) => {
    const url = new URL(requestPath, API_BASE_URL);
    const lib = url.protocol === 'https:' ? https : http;
    const payload = body ? JSON.stringify(body) : null;

    const headers = {
      Accept: 'application/json'
    };

    if (payload) {
      headers['Content-Type'] = 'application/json';
      headers['Content-Length'] = Buffer.byteLength(payload);
    }

    if (token) {
      headers.Authorization = `Bearer ${token}`;
    }

    const req = lib.request(
      {
        method,
        hostname: url.hostname,
        port: url.port || (url.protocol === 'https:' ? 443 : 80),
        path: `${url.pathname}${url.search}`,
        headers,
        timeout: 12000
      },
      (res) => {
        let raw = '';
        res.on('data', (chunk) => {
          raw += chunk;
        });
        res.on('end', () => {
          let parsed = raw;
          try {
            parsed = raw ? JSON.parse(raw) : {};
          } catch (error) {
          }

          resolve({
            status: res.statusCode,
            body: parsed
          });
        });
      }
    );

    req.on('error', reject);
    req.on('timeout', () => {
      req.destroy(new Error('request timeout'));
    });

    if (payload) {
      req.write(payload);
    }

    req.end();
  });
};

const parseSwaggerEndpoints = (swaggerPath) => {
  const lines = fs.readFileSync(swaggerPath, 'utf8').split('\n');
  const endpoints = [];
  let currentPath = null;

  for (const line of lines) {
    const pathMatch = line.match(/^\s{2}(\/[^:]+):\s*$/);
    if (pathMatch) {
      currentPath = pathMatch[1];
      continue;
    }

    const methodMatch = line.match(/^\s{4}(get|post|put|patch|delete):\s*$/i);
    if (methodMatch && currentPath) {
      endpoints.push({
        method: methodMatch[1].toUpperCase(),
        path: currentPath
      });
    }
  }

  return endpoints;
};

const buildCandidates = (rawPath) => {
  const normalizedPath = rawPath.replace(/\{[^}]+\}/g, '1');
  const candidates = [normalizedPath];

  if (!normalizedPath.startsWith('/api/')) {
    candidates.push(`/api/v1${normalizedPath}`);
    candidates.push(`/api${normalizedPath}`);
  }

  return [...new Set(candidates)];
};

const buildBody = ({ method, endpointPath, email, password, refreshToken }) => {
  if (!['POST', 'PUT', 'PATCH'].includes(method)) {
    return undefined;
  }

  if (endpointPath === '/auth/signup') {
    return {
      email,
      password,
      deviceId: `coverage-device-${Date.now()}`,
      deviceName: 'coverage-device'
    };
  }

  if (endpointPath === '/auth/signin') {
    return {
      email,
      password,
      deviceId: `coverage-device-${Date.now()}`
    };
  }

  if (endpointPath === '/auth/refresh') {
    return {
      refreshToken,
      deviceId: 'coverage-device'
    };
  }

  if (endpointPath.startsWith('/expenses') || endpointPath.startsWith('/income')) {
    return {
      amount: 10,
      category: 'General',
      description: 'Coverage test',
      date: new Date().toISOString()
    };
  }

  if (endpointPath.startsWith('/budgets')) {
    return {
      category: 'General',
      amount: 100,
      period: 'monthly'
    };
  }

  if (endpointPath.startsWith('/banks/connect')) {
    return {
      provider: 'test-bank',
      credentials: {
        token: 'dummy'
      }
    };
  }

  if (endpointPath.startsWith('/investments')) {
    return {
      name: 'Coverage Fund',
      type: 'stock',
      quantity: 1,
      purchasePrice: 10
    };
  }

  if (endpointPath.startsWith('/notifications/preferences')) {
    return {
      emailNotifications: true,
      pushNotifications: false
    };
  }

  if (endpointPath.startsWith('/settings/security')) {
    return {
      twoFactorEnabled: false
    };
  }

  if (endpointPath.startsWith('/settings')) {
    return {
      currency: 'USD'
    };
  }

  return {
    testMode: true
  };
};

describeRemote('Swagger Endpoint Coverage Smoke', () => {
  let accessToken;
  let refreshToken;
  let email;
  let password;

  beforeAll(async () => {
    email = `endpoint-cover-${Date.now()}@example.com`;
    password = `Cv!${Date.now()}Aa1`;

    const signup = await requestJson({
      method: 'POST',
      requestPath: '/api/v1/auth/signup',
      body: {
        email,
        password,
        deviceId: `coverage-${Date.now()}`,
        deviceName: 'coverage-device'
      }
    });

    if ([200, 201].includes(signup.status)) {
      accessToken = signup.body.accessToken || signup.body.token;
      refreshToken = signup.body.refreshToken;
      return;
    }

    const signin = await requestJson({
      method: 'POST',
      requestPath: '/api/v1/auth/signin',
      body: {
        email,
        password,
        deviceId: `coverage-${Date.now()}`
      }
    });

    if ([200, 201].includes(signin.status)) {
      accessToken = signin.body.accessToken || signin.body.token;
      refreshToken = signin.body.refreshToken;
    }
  });

  it('should exercise every endpoint/method from swagger without 5xx errors', async () => {
    const swaggerPath = path.resolve(process.cwd(), 'swagger.yaml');
    const endpoints = parseSwaggerEndpoints(swaggerPath);

    expect(endpoints.length).toBeGreaterThan(0);

    const failures = [];

    for (const endpoint of endpoints) {
      const candidates = buildCandidates(endpoint.path);
      const hasPathParam = endpoint.path.includes('{');
      const body = buildBody({
        method: endpoint.method,
        endpointPath: endpoint.path,
        email,
        password,
        refreshToken
      });

      let endpointPassed = false;
      let lastStatus = null;

      for (const candidate of candidates) {
        try {
          const response = await requestJson({
            method: endpoint.method,
            requestPath: candidate,
            token: accessToken,
            body
          });

          lastStatus = response.status;

          if (response.status >= 500) {
            continue;
          }

          if (response.status === 404 && !hasPathParam) {
            continue;
          }

          endpointPassed = true;
          break;
        } catch (error) {
          lastStatus = error.message;
        }
      }

      if (!endpointPassed) {
        failures.push(`${endpoint.method} ${endpoint.path} (last=${lastStatus})`);
      }
    }

    expect(failures).toEqual([]);
  }, 180000);
});
