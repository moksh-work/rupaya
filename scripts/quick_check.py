import requests
import json

# Login
r = requests.post('http://localhost:3000/api/v1/auth/signin', json={
    'email': 'iostest@example.com',
    'password': 'TestPass123!@#',
    'deviceId': 'test'
})

if r.status_code == 200:
    token = r.json()['accessToken']
    headers = {'Authorization': f'Bearer {token}'}
    
    # Get accounts
    acc = requests.get('http://localhost:3000/api/v1/accounts', headers=headers)
    print("ACCOUNTS:")
    print(json.dumps(acc.json(), indent=2))
    
    # Get transactions
    txn = requests.get('http://localhost:3000/api/v1/transactions', headers=headers)
    print("\nTRANSACTIONS COUNT:", len(txn.json()))
    if txn.json():
        print("FIRST TRANSACTION:")
        print(json.dumps(txn.json()[0], indent=2))
else:
    print("Login failed:", r.text)
