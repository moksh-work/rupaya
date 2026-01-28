#!/usr/bin/env python3
import requests
import json

resp = requests.post('http://localhost:3000/api/v1/auth/signin',
    json={'email':'iostest@example.com','password':'TestPass123!@#','deviceId':'test'})
token = resp.json()['accessToken']
dashboard = requests.get('http://localhost:3000/api/v1/analytics/dashboard?period=month',
    headers={'Authorization': f'Bearer {token}'}).json()
print(json.dumps(dashboard['spendingByCategory'], indent=2))
