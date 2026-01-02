#!/bin/bash
set -e

ENVIRONMENT="dev"
TF_DIR="terraform/environments/$ENVIRONMENT"

echo "DESTROYING Infrastructure for Environment: $ENVIRONMENT"
echo "This will delete the AKS cluster and all nodes!"
read -p "Are you sure? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

# 1. Login Check
if ! az account show > /dev/null 2>&1; then
    az login
fi

# 2. Terraform Destroy
cd "$TF_DIR"
echo "Destroying..."
terraform destroy -auto-approve

echo "✅ Destruction Complete. Billing stopped."