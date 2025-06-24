#!/usr/bin/env python3
import json
import time
import base64
import requests
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa, padding
from cryptography.hazmat.backends import default_backend

def create_jwt(service_account_data):
    # Header
    header = {
        "alg": "RS256",
        "typ": "JWT"
    }
    
    # Claims
    now = int(time.time())
    claims = {
        "iss": service_account_data["client_email"],
        "scope": "https://www.googleapis.com/auth/spreadsheets",
        "aud": "https://oauth2.googleapis.com/token",
        "iat": now,
        "exp": now + 3600
    }
    
    # Encode header and claims
    header_b64 = base64.urlsafe_b64encode(json.dumps(header).encode()).rstrip(b'=').decode()
    claims_b64 = base64.urlsafe_b64encode(json.dumps(claims).encode()).rstrip(b'=').decode()
    
    # Create payload
    payload = f"{header_b64}.{claims_b64}"
    
    # Load private key
    private_key = serialization.load_pem_private_key(
        service_account_data["private_key"].encode(),
        password=None,
        backend=default_backend()
    )
    
    # Sign payload
    signature = private_key.sign(
        payload.encode(),
        padding.PKCS1v15(),
        hashes.SHA256()
    )
    
    # Encode signature
    signature_b64 = base64.urlsafe_b64encode(signature).rstrip(b'=').decode()
    
    return f"{payload}.{signature_b64}"

def get_access_token(jwt):
    url = "https://oauth2.googleapis.com/token"
    data = {
        "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
        "assertion": jwt
    }
    
    response = requests.post(url, data=data)
    return response.json()

if __name__ == "__main__":
    # Load service account data
    with open("labX-ios/View Models/Lab Booking/labx-sheets-service-account.json", "r") as f:
        service_account_data = json.load(f)
    
    # Create JWT
    jwt = create_jwt(service_account_data)
    print(f"JWT: {jwt}")
    
    # Get access token
    result = get_access_token(jwt)
    print(f"Access Token: {result.get('access_token', 'Error: ' + str(result))}") 