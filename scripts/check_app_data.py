#!/usr/bin/env python3
"""Quick diagnostic script to check if app data is accessible"""

import requests
import json

BASE_URL = 'http://localhost:3000/api/v1'

def main():
    print("=" * 60)
    print("iOS App Data Diagnostic")
    print("=" * 60)
    
    # Login
    print("\n1. Testing Login...")
    login_response = requests.post(f'{BASE_URL}/auth/signin', json={
        'email': 'iostest@example.com',
        'password': 'TestPass123!@#',
        'deviceId': 'ios-diagnostic-001'
    })
    
    if login_response.status_code != 200:
        print(f"❌ Login failed: {login_response.status_code}")
        print(login_response.text)
        return
    
    data = login_response.json()
    token = data['accessToken']
    user_id = data['userId']
    print(f"✓ Login successful (User ID: {user_id})")
    
    headers = {'Authorization': f'Bearer {token}'}
    
    # Check Accounts
    print("\n2. Checking Accounts...")
    acc_response = requests.get(f'{BASE_URL}/accounts', headers=headers)
    if acc_response.status_code == 200:
        accounts = acc_response.json()
        print(f"✓ Found {len(accounts)} account(s)")
        for acc in accounts:
            print(f"   - {acc['account_name']}: ${acc['current_balance']}")
    else:
        print(f"❌ Accounts failed: {acc_response.status_code}")
        print(acc_response.text)
    
    # Check Transactions
    print("\n3. Checking Transactions...")
    txn_response = requests.get(f'{BASE_URL}/transactions', headers=headers)
    if txn_response.status_code == 200:
        transactions = txn_response.json()
        print(f"✓ Found {len(transactions)} transaction(s)")
        if transactions:
            print("\n   Recent transactions:")
            for txn in transactions[:5]:
                print(f"   - {txn['transaction_date']}: {txn['description']} ${txn['amount']}")
    else:
        print(f"❌ Transactions failed: {txn_response.status_code}")
        print(acc_response.text)
    
    # Check Categories
    print("\n4. Checking Categories...")
    cat_response = requests.get(f'{BASE_URL}/categories', headers=headers)
    if cat_response.status_code == 200:
        categories = cat_response.json()
        print(f"✓ Found {len(categories)} categories")
    else:
        print(f"❌ Categories failed: {cat_response.status_code}")
    
    # Check Dashboard
    print("\n5. Checking Dashboard...")
    dash_response = requests.get(f'{BASE_URL}/analytics/dashboard?period=month', headers=headers)
    if dash_response.status_code == 200:
        dashboard = dash_response.json()
        print(f"✓ Dashboard data:")
        print(f"   Income:   ${dashboard['income']}")
        print(f"   Expenses: ${dashboard['expenses']}")
        print(f"   Savings:  ${dashboard['savings']}")
        print(f"   Rate:     {dashboard['savingsRate']}")
    else:
        print(f"❌ Dashboard failed: {dash_response.status_code}")
        print(dash_response.text)
    
    print("\n" + "=" * 60)
    print("Diagnostic Complete")
    print("=" * 60)

if __name__ == '__main__':
    main()
