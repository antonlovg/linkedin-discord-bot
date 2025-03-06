#!/bin/bash
# Setup script for LinkedIn Jobs Discord Bot

set -e

echo "Setting up LinkedIn Jobs Discord Bot..."

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "Python 3 is required but not installed. Please install Python 3 and try again."
    exit 1
fi

# Check if pip is installed
if ! command -v pip3 &> /dev/null; then
    echo "pip3 is required but not installed. Please install pip3 and try again."
    exit 1
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "Terraform is required but not installed."
    echo "Please install Terraform from https://www.terraform.io/downloads.html"
    exit 1
fi

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "AWS CLI is recommended but not installed."
    echo "You can install it from https://aws.amazon.com/cli/"
    read -p "Continue without AWS CLI? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Create virtual environment
echo "Creating virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Install dependencies
echo "Installing dependencies..."
pip install -r requirements.txt

# Create lambda layer zip
echo "Creating Lambda layer zip..."
mkdir -p terraform/package
pip install -r requirements.txt -t terraform/package/python
cd terraform/package
zip -r ../lambda_layer.zip .
cd ../..

# Prompt for Discord webhook URLs
echo
echo "Please enter your Discord webhook URLs:"

read -p "Stockholm webhook URL: " stockholm_url
read -p "Oslo webhook URL: " oslo_url

# Create .env file
echo "Creating .env file..."
cat > .env << EOF
STOCKHOLM_WEBHOOK_URL=$stockholm_url
OSLO_WEBHOOK_URL=$oslo_url
EOF

# Create terraform.tfvars file
echo "Creating terraform.tfvars file..."
cat > terraform/terraform.tfvars << EOF
aws_region = "us-east-1"
stockholm_webhook_url = "$stockholm_url"
oslo_webhook_url = "$oslo_url"
EOF

echo
echo "Setup complete! You can now deploy the bot using Terraform:"
echo "cd terraform"
echo "terraform init"
echo "terraform apply"
echo
echo "Or test locally with:"
echo "python main.py"