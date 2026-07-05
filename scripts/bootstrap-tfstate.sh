#!/usr/bin/env bash
#
# Creates the Azure resources required to store Terraform/OpenTofu remote
# state: a resource group, a storage account (with versioning, soft delete,
# and TLS 1.2 minimum enforced), and a blob container.
#
# Usage:
#   ./scripts/bootstrap-tfstate.sh
#
# Configuration is via environment variables (all optional, defaults shown):
#   RESOURCE_GROUP_NAME   (default: rg-tfstate)
#   LOCATION              (default: northcentralus)
#   STORAGE_ACCOUNT_NAME  (default: sttfstate<random-suffix>, must be globally unique)
#   CONTAINER_NAME        (default: tfstate)

set -euo pipefail

RESOURCE_GROUP_NAME="${RESOURCE_GROUP_NAME:-rg-tfstate}"
LOCATION="${LOCATION:-northcentralus}"
CONTAINER_NAME="${CONTAINER_NAME:-tfstate}"

if [[ -z "${STORAGE_ACCOUNT_NAME:-}" ]]; then
  RANDOM_SUFFIX=$(LC_ALL=C tr -dc 'a-z0-9' </dev/urandom | head -c 6; true)
  STORAGE_ACCOUNT_NAME="sttfstate${RANDOM_SUFFIX}"
fi

if ! command -v az >/dev/null 2>&1; then
  echo "Error: Azure CLI (az) is not installed or not on PATH." >&2
  exit 1
fi

if ! az account show >/dev/null 2>&1; then
  echo "Error: not logged in to Azure CLI. Run 'az login' first." >&2
  exit 1
fi

read -rp "Owner tag value for these resources (e.g. your username): " OWNER_TAG
if [[ -z "${OWNER_TAG}" ]]; then
  echo "Error: Owner value cannot be empty." >&2
  exit 1
fi

echo
echo "About to create the following resources:"
echo "  Resource Group:  ${RESOURCE_GROUP_NAME}"
echo "  Location:        ${LOCATION}"
echo "  Storage Account: ${STORAGE_ACCOUNT_NAME}"
echo "  Container:       ${CONTAINER_NAME}"
echo "  Owner tag:       ${OWNER_TAG}"
echo
read -rp "Continue? [y/N] " CONFIRM
if [[ ! "${CONFIRM}" =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

echo
echo "Creating resource group..."
az group create \
  --name "${RESOURCE_GROUP_NAME}" \
  --location "${LOCATION}" \
  --tags "Owner=${OWNER_TAG}" \
  --output none

echo "Creating storage account..."
az storage account create \
  --name "${STORAGE_ACCOUNT_NAME}" \
  --resource-group "${RESOURCE_GROUP_NAME}" \
  --location "${LOCATION}" \
  --sku Standard_GRS \
  --kind StorageV2 \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --https-only true \
  --tags "Owner=${OWNER_TAG}" \
  --output none

echo "Enabling blob versioning and soft delete..."
az storage account blob-service-properties update \
  --account-name "${STORAGE_ACCOUNT_NAME}" \
  --resource-group "${RESOURCE_GROUP_NAME}" \
  --enable-versioning true \
  --enable-delete-retention true \
  --delete-retention-days 30 \
  --enable-container-delete-retention true \
  --container-delete-retention-days 30 \
  --output none

echo "Creating blob container..."
az storage container create \
  --name "${CONTAINER_NAME}" \
  --account-name "${STORAGE_ACCOUNT_NAME}" \
  --auth-mode login \
  --output none

echo
echo "Done. Add the following to backend.tf:"
cat <<EOF

terraform {
  backend "azurerm" {
    resource_group_name = "${RESOURCE_GROUP_NAME}"
    storage_account_name = "${STORAGE_ACCOUNT_NAME}"
    container_name       = "${CONTAINER_NAME}"
    key                  = "terraform.tfstate"
  }
}
EOF
