const https = require('https');
const http = require('http');
const { randomBytes } = require('crypto');

const API_BASE_URL = process.env.API_BASE_URL || 'https://staging-api.cloudycs.com';
const shouldRunRemote = process.env.RUN_REMOTE_TESTS === 'true';

const requestJson = ({ method, path, token, body }) => {
  return new Promise((resolve, reject) => {
    const url = new URL(path, API_BASE_URL);
    const lib = url.protocol === 'https:' ? https : http;
    const data = body ? JSON.stringify(body) : null;

    const headers = {
      Accept: 'application/json'
    };

    if (data) {
      headers['Content-Type'] = 'application/json';
      headers['Content-Length'] = Buffer.byteLength(data);
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
        headers
      },
      (res) => {
        let raw = '';
        res.on('data', (chunk) => {
          raw += chunk;
        });
        res.on('end', () => {
          const contentType = res.headers['content-type'] || '';
          if (contentType.includes('application/json')) {
            try {
              const parsed = raw ? JSON.parse(raw) : {};
              resolve({ status: res.statusCode, headers: res.headers, body: parsed });
            } catch (error) {
              reject(new Error(`Invalid JSON response: ${raw}`));
            }
            return;
          }

          resolve({ status: res.statusCode, headers: res.headers, body: raw });
        });
      }
    );

    req.on('error', reject);

    if (data) {
      req.write(data);
    }

    req.end();
  });
};

const getAccessToken = (payload) => payload.accessToken || payload.token;

const uniqueEmail = () => `remote-test-${Date.now()}-${Math.floor(Math.random() * 1000)}@example.com`;

const createStrongPassword = () => {
  const randomPart = randomBytes(18).toString('base64');
  return `Rt!${randomPart}Aa1@`;
};

const deviceId = `ci-device-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
const deviceName = 'ci-device';

const describeRemote = shouldRunRemote ? describe : describe.skip;

describeRemote('Remote API Smoke Tests', () => {
  let accessToken;
  let refreshToken;
  let accountId;
  let userEmail;
  let password;
  let authUnavailable = false;

  const itIfAuth = (name, fn) => (accessToken ? it(name, fn) : it.skip(name, fn));

  it('health check should return OK', async () => {
    const response = await requestJson({ method: 'GET', path: '/health' });

    expect(response.status).toBe(200);
    expect(response.body.status).toBe('OK');
    expect(response.body.timestamp).toBeDefined();
  });

  it('signup should succeed', async () => {
    if (process.env.API_TEST_ACCESS_TOKEN) {
      accessToken = process.env.API_TEST_ACCESS_TOKEN;
      refreshToken = process.env.API_TEST_REFRESH_TOKEN;
      userEmail = process.env.API_TEST_EMAIL || 'preprovided@example.com';
      return;
    }

    userEmail = uniqueEmail();
    password = createStrongPassword();
    const response = await requestJson({
      method: 'POST',
      path: '/api/v1/auth/signup',
      body: {
        email: userEmail,
        password,
        deviceId,
        deviceName
      }
    });

    if (response.status === 429) {
      authUnavailable = true;
      return;
    }

    expect(response.status).toBe(200);
    accessToken = getAccessToken(response.body);
    refreshToken = response.body.refreshToken;

    expect(accessToken).toBeDefined();
    expect(response.body.user || response.body.userId).toBeDefined();
  });

  itIfAuth('signin should succeed', async () => {
    const response = await requestJson({
      method: 'POST',
      path: '/api/v1/auth/signin',
      body: {
        email: userEmail,
        password,
        deviceId
      }
    });

    expect(response.status).toBe(200);
    const token = getAccessToken(response.body);
    expect(token).toBeDefined();
  });

  itIfAuth('profile should return user data', async () => {
    const response = await requestJson({
      method: 'GET',
      path: '/api/v1/users/profile',
      token: accessToken
    });

    expect(response.status).toBe(200);
    expect(response.body.email || response.body.user?.email).toBeDefined();
  });

  it('should reject unauthorized access', async () => {
    const response = await requestJson({
      method: 'GET',
      path: '/api/v1/accounts'
    });

    expect([401, 403]).toContain(response.status);
  });

  itIfAuth('should create an account', async () => {
    const response = await requestJson({
      method: 'POST',
      path: '/api/v1/accounts',
      token: accessToken,
      body: {
        name: 'Remote Test Cash',
        account_type: 'cash',
        currency: 'USD',
        current_balance: 1000,
        is_default: true
      }
    });

    expect(response.status).toBe(201);
    accountId = response.body.account_id || response.body.accountId || response.body.id;
    expect(accountId).toBeDefined();
  });

  itIfAuth('should list accounts', async () => {
    const response = await requestJson({
      method: 'GET',
      path: '/api/v1/accounts',
      token: accessToken
    });

    expect(response.status).toBe(200);
    expect(Array.isArray(response.body)).toBe(true);
  });

  itIfAuth('should create a transaction', async () => {
    const response = await requestJson({
      method: 'POST',
      path: '/api/v1/transactions',
      token: accessToken,
      body: {
        accountId,
        amount: 25.5,
        type: 'expense',
        currency: 'USD',
        description: 'Remote test expense',
        date: new Date().toISOString()
      }
    });

    expect(response.status).toBe(201);
    const transactionId = response.body.transaction_id || response.body.transactionId || response.body.id;
    expect(transactionId).toBeDefined();
  });

  itIfAuth('should list transactions', async () => {
    const response = await requestJson({
      method: 'GET',
      path: '/api/v1/transactions?limit=10',
      token: accessToken
    });

    expect(response.status).toBe(200);
    expect(Array.isArray(response.body)).toBe(true);
  });

  itIfAuth('should return analytics dashboard', async () => {
    const response = await requestJson({
      method: 'GET',
      path: '/api/v1/analytics/dashboard',
      token: accessToken
    });

    expect(response.status).toBe(200);
    expect(response.body).toBeDefined();
  });

  itIfAuth('should list categories', async () => {
    const response = await requestJson({
      method: 'GET',
      path: '/api/v1/categories',
      token: accessToken
    });

    expect(response.status).toBe(200);
    expect(Array.isArray(response.body)).toBe(true);
  });

  itIfAuth('logout should succeed', async () => {
    const response = await requestJson({
      method: 'POST',
      path: '/api/v1/auth/logout',
      token: accessToken,
      body: refreshToken ? { refreshToken } : undefined
    });

    expect(response.status).toBe(200);
  });

  afterAll(() => {
    if (!accessToken && authUnavailable) {
      // eslint-disable-next-line no-console
      console.warn('Auth tests skipped: auth rate limit hit. Provide API_TEST_ACCESS_TOKEN to run full suite.');
    }
  });
});
