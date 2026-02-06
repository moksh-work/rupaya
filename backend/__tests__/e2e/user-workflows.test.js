/**
 * End-to-End Tests for Complete User Workflows
 * Tests realistic user journeys through the application
 */

const request = require('supertest');
const app = require('../../../src/app');

describe('End-to-End Tests - User Workflows', () => {
  describe('E2E: New User Onboarding Flow', () => {
    it('should complete full onboarding workflow', async () => {
      const userEmail = `e2e-onboard-${Date.now()}@example.com`;
      const userPassword = 'E2ETest123!@#';

      // Step 1: Sign up
      const signupRes = await request(app)
        .post('/api/auth/signup')
        .send({
          email: userEmail,
          password: userPassword,
          firstName: 'E2E',
          lastName: 'User'
        });

      expect(signupRes.status).toBe(201);
      const token = signupRes.body.token;
      const userId = signupRes.body.user.id;

      // Step 2: Get profile
      const profileRes = await request(app)
        .get('/api/user/profile')
        .set('Authorization', `Bearer ${token}`);

      expect(profileRes.status).toBe(200);
      expect(profileRes.body.email).toBe(userEmail);

      // Step 3: Create first account
      const accountRes = await request(app)
        .post('/api/accounts')
        .set('Authorization', `Bearer ${token}`)
        .send({
          name: 'My Checking Account',
          type: 'checking',
          balance: 5000,
          currency: 'USD'
        });

      expect(accountRes.status).toBe(201);
      const accountId = accountRes.body.id;

      // Step 4: Add initial transactions
      const transaction1 = await request(app)
        .post('/api/transactions')
        .set('Authorization', `Bearer ${token}`)
        .send({
          description: 'Monthly Salary',
          amount: 3000,
          category: 'Income',
          type: 'income',
          accountId: accountId,
          date: new Date().toISOString()
        });

      expect(transaction1.status).toBe(201);

      const transaction2 = await request(app)
        .post('/api/transactions')
        .set('Authorization', `Bearer ${token}`)
        .send({
          description: 'Grocery Shopping',
          amount: 150,
          category: 'Food',
          type: 'expense',
          accountId: accountId,
          date: new Date().toISOString()
        });

      expect(transaction2.status).toBe(201);

      // Step 5: Check dashboard
      const dashboardRes = await request(app)
        .get('/api/dashboard')
        .set('Authorization', `Bearer ${token}`);

      expect(dashboardRes.status).toBe(200);
      expect(dashboardRes.body.balance).toBe(5000 + 3000 - 150);
      expect(dashboardRes.body.transactions.length).toBeGreaterThan(0);

      // Step 6: View analytics
      const analyticsRes = await request(app)
        .get('/api/analytics/summary')
        .set('Authorization', `Bearer ${token}`);

      expect(analyticsRes.status).toBe(200);
      expect(analyticsRes.body.totalIncome).toBe(3000);
      expect(analyticsRes.body.totalExpenses).toBe(150);
    });
  });

  describe('E2E: Multiple Accounts Management', () => {
    let token;

    beforeAll(async () => {
      const signupRes = await request(app)
        .post('/api/auth/signup')
        .send({
          email: `e2e-multi-${Date.now()}@example.com`,
          password: 'E2ETest123!@#',
          firstName: 'Multi',
          lastName: 'Account'
        });

      token = signupRes.body.token;
    });

    it('should manage multiple accounts and transactions', async () => {
      // Create Checking Account
      const checking = await request(app)
        .post('/api/accounts')
        .set('Authorization', `Bearer ${token}`)
        .send({
          name: 'Checking Account',
          type: 'checking',
          balance: 2000,
          currency: 'USD'
        });

      expect(checking.status).toBe(201);
      const checkingId = checking.body.id;

      // Create Savings Account
      const savings = await request(app)
        .post('/api/accounts')
        .set('Authorization', `Bearer ${token}`)
        .send({
          name: 'Savings Account',
          type: 'savings',
          balance: 10000,
          currency: 'USD'
        });

      expect(savings.status).toBe(201);
      const savingsId = savings.body.id;

      // Add expense to checking
      const checkingExpense = await request(app)
        .post('/api/transactions')
        .set('Authorization', `Bearer ${token}`)
        .send({
          description: 'Gas',
          amount: 50,
          category: 'Transport',
          type: 'expense',
          accountId: checkingId,
          date: new Date().toISOString()
        });

      expect(checkingExpense.status).toBe(201);

      // Add income to savings
      const savingsIncome = await request(app)
        .post('/api/transactions')
        .set('Authorization', `Bearer ${token}`)
        .send({
          description: 'Interest',
          amount: 25,
          category: 'Interest',
          type: 'income',
          accountId: savingsId,
          date: new Date().toISOString()
        });

      expect(savingsIncome.status).toBe(201);

      // Get all accounts
      const accountsRes = await request(app)
        .get('/api/accounts')
        .set('Authorization', `Bearer ${token}`);

      expect(accountsRes.status).toBe(200);
      expect(accountsRes.body.data.length).toBe(2);

      // Get checking account transactions
      const checkingTx = await request(app)
        .get(`/api/accounts/${checkingId}/transactions`)
        .set('Authorization', `Bearer ${token}`);

      expect(checkingTx.status).toBe(200);
      expect(checkingTx.body.data.length).toBe(1);

      // Get savings account transactions
      const savingsTx = await request(app)
        .get(`/api/accounts/${savingsId}/transactions`)
        .set('Authorization', `Bearer ${token}`);

      expect(savingsTx.status).toBe(200);
      expect(savingsTx.body.data.length).toBe(1);
    });
  });

  describe('E2E: Budget Tracking Workflow', () => {
    let token;

    beforeAll(async () => {
      const signupRes = await request(app)
        .post('/api/auth/signup')
        .send({
          email: `e2e-budget-${Date.now()}@example.com`,
          password: 'E2ETest123!@#',
          firstName: 'Budget',
          lastName: 'User'
        });

      token = signupRes.body.token;
    });

    it('should create and track budgets', async () => {
      // Create budget
      const budgetRes = await request(app)
        .post('/api/budgets')
        .set('Authorization', `Bearer ${token}`)
        .send({
          category: 'Food',
          limit: 500,
          month: new Date().toISOString()
        });

      expect(budgetRes.status).toBe(201);
      const budgetId = budgetRes.body.id;

      // Create account for transactions
      const accountRes = await request(app)
        .post('/api/accounts')
        .set('Authorization', `Bearer ${token}`)
        .send({
          name: 'Test Account',
          type: 'checking',
          balance: 1000,
          currency: 'USD'
        });

      const accountId = accountRes.body.id;

      // Add transactions
      const tx1 = await request(app)
        .post('/api/transactions')
        .set('Authorization', `Bearer ${token}`)
        .send({
          description: 'Restaurant',
          amount: 50,
          category: 'Food',
          type: 'expense',
          accountId: accountId,
          date: new Date().toISOString()
        });

      expect(tx1.status).toBe(201);

      const tx2 = await request(app)
        .post('/api/transactions')
        .set('Authorization', `Bearer ${token}`)
        .send({
          description: 'Groceries',
          amount: 100,
          category: 'Food',
          type: 'expense',
          accountId: accountId,
          date: new Date().toISOString()
        });

      expect(tx2.status).toBe(201);

      // Check budget status
      const budgetStatus = await request(app)
        .get(`/api/budgets/${budgetId}`)
        .set('Authorization', `Bearer ${token}`);

      expect(budgetStatus.status).toBe(200);
      expect(budgetStatus.body.spent).toBe(150);
      expect(budgetStatus.body.remaining).toBe(350);
      expect(budgetStatus.body.percentUsed).toBe(30);
    });
  });

  describe('E2E: Goal Setting and Tracking', () => {
    let token;

    beforeAll(async () => {
      const signupRes = await request(app)
        .post('/api/auth/signup')
        .send({
          email: `e2e-goal-${Date.now()}@example.com`,
          password: 'E2ETest123!@#',
          firstName: 'Goal',
          lastName: 'User'
        });

      token = signupRes.body.token;
    });

    it('should create and update financial goals', async () => {
      // Create goal
      const goalRes = await request(app)
        .post('/api/goals')
        .set('Authorization', `Bearer ${token}`)
        .send({
          name: 'Emergency Fund',
          targetAmount: 5000,
          currentAmount: 1000,
          deadline: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000).toISOString(),
          category: 'Savings'
        });

      expect(goalRes.status).toBe(201);
      const goalId = goalRes.body.id;

      // Update progress
      const updateRes = await request(app)
        .patch(`/api/goals/${goalId}`)
        .set('Authorization', `Bearer ${token}`)
        .send({
          currentAmount: 2000
        });

      expect(updateRes.status).toBe(200);
      expect(updateRes.body.currentAmount).toBe(2000);
      expect(updateRes.body.progressPercentage).toBe(40);

      // Get goal details
      const goalDetails = await request(app)
        .get(`/api/goals/${goalId}`)
        .set('Authorization', `Bearer ${token}`);

      expect(goalDetails.status).toBe(200);
      expect(goalDetails.body.remainingAmount).toBe(3000);
    });
  });

  describe('E2E: Report Generation', () => {
    let token;
    let accountId;

    beforeAll(async () => {
      const signupRes = await request(app)
        .post('/api/auth/signup')
        .send({
          email: `e2e-report-${Date.now()}@example.com`,
          password: 'E2ETest123!@#',
          firstName: 'Report',
          lastName: 'User'
        });

      token = signupRes.body.token;

      const accountRes = await request(app)
        .post('/api/accounts')
        .set('Authorization', `Bearer ${token}`)
        .send({
          name: 'Test Account',
          type: 'checking',
          balance: 10000,
          currency: 'USD'
        });

      accountId = accountRes.body.id;
    });

    it('should generate monthly report', async () => {
      // Add multiple transactions
      const transactions = [
        { description: 'Salary', amount: 3000, category: 'Income', type: 'income' },
        { description: 'Rent', amount: 1000, category: 'Housing', type: 'expense' },
        { description: 'Groceries', amount: 300, category: 'Food', type: 'expense' },
        { description: 'Gas', amount: 50, category: 'Transport', type: 'expense' }
      ];

      for (const tx of transactions) {
        await request(app)
          .post('/api/transactions')
          .set('Authorization', `Bearer ${token}`)
          .send({
            ...tx,
            accountId: accountId,
            date: new Date().toISOString()
          });
      }

      // Generate report
      const reportRes = await request(app)
        .get('/api/reports/monthly')
        .set('Authorization', `Bearer ${token}`)
        .query({
          month: new Date().getMonth() + 1,
          year: new Date().getFullYear()
        });

      expect(reportRes.status).toBe(200);
      expect(reportRes.body.totalIncome).toBe(3000);
      expect(reportRes.body.totalExpenses).toBe(1350);
      expect(reportRes.body.categoryBreakdown).toBeDefined();
    });

    it('should export report as CSV', async () => {
      const reportRes = await request(app)
        .get('/api/reports/monthly/export')
        .set('Authorization', `Bearer ${token}`)
        .query({
          format: 'csv',
          month: new Date().getMonth() + 1,
          year: new Date().getFullYear()
        });

      expect(reportRes.status).toBe(200);
      expect(reportRes.headers['content-type']).toContain('text/csv');
    });
  });

  describe('E2E: Error Recovery', () => {
    let token;

    beforeAll(async () => {
      const signupRes = await request(app)
        .post('/api/auth/signup')
        .send({
          email: `e2e-error-${Date.now()}@example.com`,
          password: 'E2ETest123!@#',
          firstName: 'Error',
          lastName: 'Test'
        });

      token = signupRes.body.token;
    });

    it('should handle and recover from transaction errors', async () => {
      // Try to add transaction without required fields
      const invalidRes = await request(app)
        .post('/api/transactions')
        .set('Authorization', `Bearer ${token}`)
        .send({
          description: 'Incomplete'
        });

      expect(invalidRes.status).toBe(400);

      // Verify user can still make valid transaction
      const accountRes = await request(app)
        .post('/api/accounts')
        .set('Authorization', `Bearer ${token}`)
        .send({
          name: 'Recovery Account',
          type: 'checking',
          balance: 1000,
          currency: 'USD'
        });

      const validRes = await request(app)
        .post('/api/transactions')
        .set('Authorization', `Bearer ${token}`)
        .send({
          description: 'Valid Transaction',
          amount: 100,
          category: 'Food',
          type: 'expense',
          accountId: accountRes.body.id,
          date: new Date().toISOString()
        });

      expect(validRes.status).toBe(201);
    });
  });
});
