#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Configuration
ENVIRONMENT="dev"
TF_DIR="terraform/environments/$ENVIRONMENT"
TF_VARS_FILE="terraform.tfvars"

echo "Starting Deployment for Environment: $ENVIRONMENT"

# 1. Check Azure Login Status
echo "Checking Azure authentication..."
if ! az account show > /dev/null 2>&1; then
    echo "Error: You are not logged in. Please log in now."
    az login
else
    echo "Authenticated as: $(az account show --query user.name -o tsv)"
fi

# 2. Check for tfvars
if [ ! -f "$TF_DIR/$TF_VARS_FILE" ]; then
    echo "Error: $TF_VARS_FILE not found in $TF_DIR"
    echo "Please create it and add your 'subscription_id'."
    exit 1
fi

# 3. Navigate to Terraform Directory
cd "$TF_DIR"

# 4. Initialize Terraform
echo "Initializing Terraform..."
terraform init -upgrade

# 5. Apply Infrastructure
echo "Applying Infrastructure (This may take 10-15 mins)..."
terraform apply -auto-approve -lock-timeout=5m

echo ""
echo "Deployment Complete."
echo "To configure kubectl, run the following command:"
echo "az aks get-credentials --resource-group falcon-$ENVIRONMENT-rg --name falcon-$ENVIRONMENT-aks"