#!/bin/bash
set -e

RESOURCE_GROUP_NAME="tfstate-rg" 
STORAGE_ACCOUNT_NAME="mustafastate123"     
CONTAINER_NAME="tfstate" 
LOCATION="falcon-dev.tfstate"  

if ! az account show > /dev/null 2>&1; then
    echo "Error: You are not logged in to Azure CLI."
    exit 1
fi

az group create --name $RESOURCE_GROUP_NAME --location $LOCATION -o none

az storage account create \
    --resource-group $RESOURCE_GROUP_NAME \
    --name $STORAGE_ACCOUNT_NAME \
    --sku Standard_LRS \
    --encryption-services blob \
    -o none

az storage container create \
    --name $CONTAINER_NAME \
    --account-name $STORAGE_ACCOUNT_NAME \
    -o none

echo "backend \"azurerm\" {"
echo "  resource_group_name  = \"$RESOURCE_GROUP_NAME\""
echo "  storage_account_name = \"$STORAGE_ACCOUNT_NAME\""
echo "  container_name       = \"$CONTAINER_NAME\""
echo "  key                  = \"falcon-dev.tfstate\""
echo "}"