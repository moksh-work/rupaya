#!/usr/bin/env python3
import requests
import json

resp = requests.post('http://localhost:3000/api/v1/auth/signin',
    json={'email':'iostest@example.com','password':'TestPass123!@#','deviceId':'test'})
token = resp.json()['accessToken']
headers = {'Authorization': f'Bearer {token}'}

print("Testing /api/v1/transactions endpoint:")
txns = requests.get('http://localhost:3000/api/v1/transactions?limit=100', headers=headers)
print(f'Status: {txns.status_code}')
print(f'Type: {type(txns.json())}')

data = txns.json()
if isinstance(data, list):
    print(f'Count: {len(data)}')
    if len(data) > 0:
        print('\nFirst transaction:')
        print(json.dumps(data[0], indent=2))
else:
    print(f'Response: {data}')
