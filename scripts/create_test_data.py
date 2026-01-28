#!/usr/bin/env python3
import requests
import json
from datetime import datetime, timedelta

print("=" * 60)
print("RUPAYA Test Data Generator")
print("=" * 60)

# Sign in
print("\n1. Authenticating...")
resp = requests.post('http://localhost:3000/api/v1/auth/signin',
    json={"email":"iostest@example.com","password":"TestPass123!@#","deviceId":"test"})
token = resp.json()['accessToken']
headers = {'Authorization': f'Bearer {token}'}
print("✓ Authenticated successfully")

# Get existing accounts
print("\n2. Setting up accounts...")
accounts = requests.get('http://localhost:3000/api/v1/accounts', headers=headers).json()
print(f"   Found {len(accounts)} existing account(s)")

# Create additional accounts if needed
account_configs = [
    {"name": "Savings Account", "account_type": "savings", "currency": "USD", "current_balance": 5000, "is_default": False},
    {"name": "Credit Card", "account_type": "credit_card", "currency": "USD", "current_balance": 0, "is_default": False},
]

created_accounts = []
for acc_config in account_configs:
    # Check if account already exists
    if not any(a['name'] == acc_config['name'] for a in accounts):
        resp = requests.post('http://localhost:3000/api/v1/accounts', json=acc_config, headers=headers)
        if resp.status_code == 201:
            created_accounts.append(resp.json())
            print(f"   ✓ Created account: {acc_config['name']}")

# Refresh accounts list
accounts = requests.get('http://localhost:3000/api/v1/accounts', headers=headers).json()
main_account = next((a for a in accounts if 'Wallet' in a['name'] or a.get('is_default')), accounts[0])
savings_account = next((a for a in accounts if 'Savings' in a['name']), None)
credit_card = next((a for a in accounts if 'Credit' in a['name']), None)

print(f"   Total accounts: {len(accounts)}")

# Get categories
print("\n3. Loading categories...")
categories = requests.get('http://localhost:3000/api/v1/categories', headers=headers).json()

# Create category lookup
cat_map = {}
for cat in categories:
    cat_map[cat['name']] = cat['category_id']

print(f"   Found {len(categories)} categories")

# Create comprehensive test transactions
print("\n4. Creating test transactions...")
base_date = datetime(2026, 1, 1)

transactions_data = [
    # Income transactions
    {"date": "2026-01-01", "accountId": main_account['account_id'], "amount": 5000, "type": "income", "category": "Salary", "description": "January Salary"},
    {"date": "2026-01-15", "accountId": savings_account['account_id'] if savings_account else main_account['account_id'], "amount": 500, "type": "income", "category": "Investment", "description": "Stock dividends"},
    {"date": "2026-01-20", "accountId": main_account['account_id'], "amount": 200, "type": "income", "category": "Business", "description": "Freelance project"},
    
    # Groceries & Food
    {"date": "2026-01-03", "accountId": main_account['account_id'], "amount": 125.50, "type": "expense", "category": "Groceries", "description": "Whole Foods shopping"},
    {"date": "2026-01-08", "accountId": main_account['account_id'], "amount": 89.99, "type": "expense", "category": "Groceries", "description": "Weekend groceries"},
    {"date": "2026-01-15", "accountId": main_account['account_id'], "amount": 156.75, "type": "expense", "category": "Groceries", "description": "Monthly grocery run"},
    {"date": "2026-01-22", "accountId": main_account['account_id'], "amount": 98.30, "type": "expense", "category": "Groceries", "description": "Fresh produce"},
    {"date": "2026-01-27", "accountId": main_account['account_id'], "amount": 112.40, "type": "expense", "category": "Groceries", "description": "Week supplies"},
    
    # Dining & Restaurants
    {"date": "2026-01-05", "accountId": credit_card['account_id'] if credit_card else main_account['account_id'], "amount": 45.99, "type": "expense", "category": "Dining & Restaurants", "description": "Dinner at Italian restaurant"},
    {"date": "2026-01-10", "accountId": main_account['account_id'], "amount": 28.50, "type": "expense", "category": "Dining & Restaurants", "description": "Lunch meeting"},
    {"date": "2026-01-14", "accountId": credit_card['account_id'] if credit_card else main_account['account_id'], "amount": 67.80, "type": "expense", "category": "Dining & Restaurants", "description": "Date night"},
    {"date": "2026-01-18", "accountId": main_account['account_id'], "amount": 22.30, "type": "expense", "category": "Dining & Restaurants", "description": "Coffee shop"},
    {"date": "2026-01-25", "accountId": main_account['account_id'], "amount": 52.90, "type": "expense", "category": "Dining & Restaurants", "description": "Weekend brunch"},
    
    # Transportation
    {"date": "2026-01-04", "accountId": main_account['account_id'], "amount": 65.00, "type": "expense", "category": "Transportation", "description": "Gas station"},
    {"date": "2026-01-12", "accountId": main_account['account_id'], "amount": 45.00, "type": "expense", "category": "Transportation", "description": "Gas refill"},
    {"date": "2026-01-19", "accountId": main_account['account_id'], "amount": 25.50, "type": "expense", "category": "Transportation", "description": "Uber rides"},
    {"date": "2026-01-23", "accountId": main_account['account_id'], "amount": 55.00, "type": "expense", "category": "Transportation", "description": "Gas"},
    
    # Shopping
    {"date": "2026-01-06", "accountId": credit_card['account_id'] if credit_card else main_account['account_id'], "amount": 89.99, "type": "expense", "category": "Shopping", "description": "Amazon order"},
    {"date": "2026-01-11", "accountId": credit_card['account_id'] if credit_card else main_account['account_id'], "amount": 145.00, "type": "expense", "category": "Shopping", "description": "Clothing store"},
    {"date": "2026-01-17", "accountId": main_account['account_id'], "amount": 75.50, "type": "expense", "category": "Shopping", "description": "Electronics accessories"},
    {"date": "2026-01-24", "accountId": credit_card['account_id'] if credit_card else main_account['account_id'], "amount": 199.99, "type": "expense", "category": "Shopping", "description": "New headphones"},
    
    # Bills & Utilities
    {"date": "2026-01-02", "accountId": main_account['account_id'], "amount": 120.00, "type": "expense", "category": "Bills & Utilities", "description": "Electricity bill"},
    {"date": "2026-01-05", "accountId": main_account['account_id'], "amount": 65.00, "type": "expense", "category": "Bills & Utilities", "description": "Internet bill"},
    {"date": "2026-01-07", "accountId": main_account['account_id'], "amount": 45.00, "type": "expense", "category": "Bills & Utilities", "description": "Water bill"},
    {"date": "2026-01-10", "accountId": main_account['account_id'], "amount": 89.99, "type": "expense", "category": "Bills & Utilities", "description": "Phone bill"},
    
    # Entertainment
    {"date": "2026-01-09", "accountId": main_account['account_id'], "amount": 15.99, "type": "expense", "category": "Entertainment", "description": "Netflix subscription"},
    {"date": "2026-01-13", "accountId": credit_card['account_id'] if credit_card else main_account['account_id'], "amount": 45.00, "type": "expense", "category": "Entertainment", "description": "Movie tickets"},
    {"date": "2026-01-21", "accountId": main_account['account_id'], "amount": 12.99, "type": "expense", "category": "Entertainment", "description": "Spotify premium"},
    
    # Healthcare
    {"date": "2026-01-16", "accountId": main_account['account_id'], "amount": 35.00, "type": "expense", "category": "Healthcare", "description": "Pharmacy"},
    {"date": "2026-01-26", "accountId": main_account['account_id'], "amount": 150.00, "type": "expense", "category": "Healthcare", "description": "Doctor visit"},
    
    # Education
    {"date": "2026-01-12", "accountId": main_account['account_id'], "amount": 49.99, "type": "expense", "category": "Education", "description": "Online course"},
]

created_count = 0
failed_count = 0

for txn_data in transactions_data:
    category_id = cat_map.get(txn_data['category'])
    if not category_id:
        print(f"   ⚠ Category not found: {txn_data['category']}")
        continue
    
    txn_request = {
        "accountId": txn_data['accountId'],
        "amount": txn_data['amount'],
        "type": txn_data['type'],
        "categoryId": category_id,
        "description": txn_data['description'],
        "date": f"{txn_data['date']}T12:00:00Z"
    }
    
    resp = requests.post('http://localhost:3000/api/v1/transactions', json=txn_request, headers=headers)
    if resp.status_code == 201:
        created_count += 1
        print(f"   ✓ {txn_data['date']}: {txn_data['description']} (${txn_data['amount']})")
    else:
        failed_count += 1
        if resp.status_code != 409:  # Don't show duplicate errors
            print(f"   ✗ Failed: {txn_data['description']} - {resp.status_code}")

print(f"\n   Created {created_count} new transactions")
if failed_count > 0:
    print(f"   Skipped {failed_count} transactions (likely duplicates)")

# Get final stats
print("\n5. Verifying data...")
transactions = requests.get('http://localhost:3000/api/v1/transactions', headers=headers).json()
print(f"   Total transactions in database: {len(transactions)}")

# Dashboard analytics
print("\n6. Dashboard Analytics:")
for period in ['week', 'month', 'year']:
    dashboard = requests.get(f'http://localhost:3000/api/v1/analytics/dashboard?period={period}', headers=headers).json()
    print(f"\n   {period.upper()}:")
    print(f"   • Income:        ${dashboard['income']:.2f}")
    print(f"   • Expenses:      ${dashboard['expenses']:.2f}")
    print(f"   • Savings:       ${dashboard['savings']:.2f}")
    print(f"   • Savings Rate:  {dashboard['savingsRate']}%")
    
    if dashboard['spendingByCategory']:
        print(f"\n   Top Spending Categories ({period}):")
        for cat in dashboard['spendingByCategory'][:5]:
            print(f"   • {cat['category']}: ${cat['amount']:.2f}")

print("\n" + "=" * 60)
print("✓ Test data generation completed!")
print("=" * 60)
