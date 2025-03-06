#!/usr/bin/env python3
"""
Local test script for LinkedIn Jobs Discord Bot.
This simulates running the Lambda function locally.
"""

import os
import json
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Check if webhook URLs are set
required_env_vars = ["STOCKHOLM_WEBHOOK_URL", "OSLO_WEBHOOK_URL"]
missing_vars = [var for var in required_env_vars if not os.getenv(var)]

if missing_vars:
    print(f"Error: Missing environment variables: {', '.join(missing_vars)}")
    print("Please create a .env file with the required variables.")
    exit(1)

# Import the lambda handler
try:
    import sys
    sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    from main import lambda_handler
except ImportError as e:
    print(f"Error importing main.py: {e}")
    print("Make sure you have installed all dependencies:")
    print("pip install -r requirements.txt")
    exit(1)

print("Testing LinkedIn Jobs Discord Bot locally...")
print("This will send real messages to your Discord webhooks!")
response = input("Continue? (y/n): ")

if response.lower() != "y":
    print("Test cancelled.")
    exit(0)

# Create a mock event and context
event = {}
context = {}

# Run the lambda handler
try:
    result = lambda_handler(event, context)
    print(f"Success! Lambda returned: {json.dumps(result, indent=2)}")
except Exception as e:
    print(f"Error running lambda_handler: {e}")
    exit(1)

print("\nCheck your Discord channels to verify the messages were sent.")
print("Note: If no new jobs were found, no messages will appear.")