import requests

# 1. Signup to get a token
signup_url = "http://localhost:3000/api/v1/auth/signup"
signup_payload = {
    "email": "apitest+account@example.com",
    "password": "SuperSecurePassword123!",
    "deviceId": "apitest-device-001",
    "deviceName": "API Test Device"
}
signup_resp = requests.post(signup_url, json=signup_payload)
print("Signup status:", signup_resp.status_code)
print("Signup response:", signup_resp.json())

token = signup_resp.json().get("accessToken")
if not token:
    print("No token received, cannot continue.")
else:
    # 2. Create account with token
    account_url = "http://localhost:3000/api/v1/accounts"
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    account_payload = {
        "name": "Test Account",
        "account_type": "cash",
        "currency": "INR",
        "current_balance": 1000.0,
        "is_default": True,
        "icon": "wallet",
        "color": "#00FF00"
    }
    account_resp = requests.post(account_url, json=account_payload, headers=headers)
    print("Account create status:", account_resp.status_code)
    print("Account create response:", account_resp.json())