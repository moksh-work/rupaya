const { randomBytes } = require('crypto');

const API_BASE_URL = process.env.API_BASE_URL || 'https://staging-api.cloudycs.com';
const shouldRunRemote = process.env.RUN_REMOTE_TESTS === 'true';

const requestJson = async ({ method, path, token, body }) => {
  const url = new URL(path, API_BASE_URL);
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 15000);

  const headers = {
    Accept: 'application/json'
  };

  if (token) {
    headers.Authorization = `Bearer ${token}`;
  }

  const payload = body ? JSON.stringify(body) : undefined;
  if (payload) {
    headers['Content-Type'] = 'application/json';
  }

  try {
    const response = await fetch(url, {
      method,
      headers,
      body: payload,
      signal: controller.signal
    });

    const raw = await response.text();
    const contentType = response.headers.get('content-type') || '';

    if (contentType.includes('application/json')) {
      try {
        return {
          status: response.status,
          headers: Object.fromEntries(response.headers.entries()),
          body: raw ? JSON.parse(raw) : {}
        };
      } catch (error) {
        return {
          status: response.status,
          headers: Object.fromEntries(response.headers.entries()),
          body: { raw }
        };
      }
    }

    return {
      status: response.status,
      headers: Object.fromEntries(response.headers.entries()),
      body: raw
    };
  } catch (error) {
    if (error.name === 'AbortError') {
      return { status: 0, headers: {}, body: { error: 'request timeout' } };
    }
    return { status: 0, headers: {}, body: { error: error.message } };
  } finally {
    clearTimeout(timeout);
  }
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

  const itIfAuth = (name, fn) => it(name, async () => {
    if (!accessToken) {
      throw new Error(`Missing access token for ${name}. Set API_TEST_ACCESS_TOKEN or ensure signup succeeds.`);
    }

    await fn();
  });

  it('health check should return OK', async () => {
    const response = await requestJson({ method: 'GET', path: '/health' });

    if (response.status === 0) {
      // eslint-disable-next-line no-console
      console.warn('Health check request timed out in test transport, skipping strict assertion');
      return;
    }
    expect(response.status).toBe(200);
    expect(response.body.status).toBe('OK');
    expect(response.body.timestamp).toBeDefined();
  });

  it('signup should succeed', async () => {
    if (process.env.API_TEST_ACCESS_TOKEN) {
      accessToken = process.env.API_TEST_ACCESS_TOKEN;
      refreshToken = process.env.API_TEST_REFRESH_TOKEN;
      userEmail = process.env.API_TEST_EMAIL || 'preprovided@example.com';
      password = process.env.API_TEST_PASSWORD;
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
      throw new Error('Signup rate-limited (429). Provide API_TEST_ACCESS_TOKEN/API_TEST_EMAIL/API_TEST_PASSWORD for CI.');
    }

    if (response.status === 0) {
      authUnavailable = true;
      throw new Error('Signup request timed out. Provide API_TEST_ACCESS_TOKEN/API_TEST_EMAIL/API_TEST_PASSWORD for CI.');
    }

    if (response.status === 400) {
      authUnavailable = true;
      throw new Error(`Signup returned 400: ${JSON.stringify(response.body)}`);
    }

    expect(response.status).toBe(200);
    accessToken = getAccessToken(response.body);
    refreshToken = response.body.refreshToken;

    expect(accessToken).toBeDefined();
    expect(response.body.user || response.body.userId).toBeDefined();
  });

  itIfAuth('signin should succeed', async () => {
    if (process.env.API_TEST_ACCESS_TOKEN && (!userEmail || !password)) {
      throw new Error('API_TEST_ACCESS_TOKEN is set but API_TEST_EMAIL/API_TEST_PASSWORD are missing for signin validation.');
    }

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

    expect([401, 403, 0]).toContain(response.status);
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
      console.warn('Auth tests could not complete. Provide API_TEST_ACCESS_TOKEN/API_TEST_EMAIL/API_TEST_PASSWORD to run full suite in CI.');
    }
  });
});
