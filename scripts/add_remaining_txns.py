#!/usr/bin/env python3
import requests

resp = requests.post('http://localhost:3000/api/v1/auth/signin',
    json={"email":"iostest@example.com","password":"TestPass123!@#","deviceId":"test"})
token = resp.json()['accessToken']
headers = {'Authorization': f'Bearer {token}'}

accounts = requests.get('http://localhost:3000/api/v1/accounts', headers=headers).json()
categories = requests.get('http://localhost:3000/api/v1/categories', headers=headers).json()

main_account = accounts[0]['account_id']
cat_map = {c['name']: c['category_id'] for c in categories}

# Create the remaining transactions
failed_txns = [
    {"date": "2026-01-05", "amount": 45.99, "category": "Dining & Restaurants", "description": "Dinner at Italian restaurant"},
    {"date": "2026-01-14", "amount": 67.80, "category": "Dining & Restaurants", "description": "Date night"},
    {"date": "2026-01-06", "amount": 89.99, "category": "Shopping", "description": "Amazon order"},
    {"date": "2026-01-11", "amount": 145.00, "category": "Shopping", "description": "Clothing store"},
    {"date": "2026-01-24", "amount": 199.99, "category": "Shopping", "description": "New headphones"},
    {"date": "2026-01-13", "amount": 45.00, "category": "Entertainment", "description": "Movie tickets"},
]

created = 0
for txn in failed_txns:
    req = {
        "accountId": main_account,
        "amount": txn['amount'],
        "type": "expense",
        "categoryId": cat_map[txn['category']],
        "description": txn['description'],
        "date": f"{txn['date']}T12:00:00Z"
    }
    resp = requests.post('http://localhost:3000/api/v1/transactions', json=req, headers=headers)
    if resp.status_code == 201:
        created += 1
        print(f"✓ {txn['description']}")

print(f"\n✓ Created {created} additional transactions")

# Final stats
txns = requests.get('http://localhost:3000/api/v1/transactions', headers=headers).json()
dashboard = requests.get('http://localhost:3000/api/v1/analytics/dashboard?period=month', headers=headers).json()

print(f"\nFinal Statistics:")
print(f"• Total Accounts: {len(accounts)}")
print(f"• Total Transactions: {len(txns)}")
print(f"• Monthly Income: ${dashboard['income']:.2f}")
print(f"• Monthly Expenses: ${dashboard['expenses']:.2f}")
print(f"• Monthly Savings: ${dashboard['savings']:.2f}")
print(f"• Savings Rate: {dashboard['savingsRate']}%")
