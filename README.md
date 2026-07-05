# Microsoft Foundry Playground (Terraform)

Infrastructure-as-code for a Microsoft Foundry (Azure AI Foundry) playground
environment on Azure. Provisions the base resource group today, with the
following resources planned:

- Key Vault
- Application Insights
- Storage Account
- Virtual Network
- Azure AI Foundry (AIF)
- Log Analytics
- AI Foundry Project

The stack is written for both [OpenTofu](https://opentofu.org/) and
[Terraform](https://www.terraform.io/) using the `azurerm` provider
(`~> 4.80`).

## Prerequisites

- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) (`az`), logged in via `az login`
- OpenTofu and/or Terraform:
  - [tfenv](https://github.com/tfutils/tfenv) manages the Terraform version pinned in [.terraform-version](.terraform-version)
  - [tofuenv](https://github.com/tofuutils/tofuenv) manages the OpenTofu version pinned in [.opentofu-version](.opentofu-version)

```bash
# Terraform via tfenv
tfenv install
tfenv use

# OpenTofu via tofuenv
tofuenv install
tofuenv use
```

## Bootstrapping remote state

Terraform/OpenTofu state is stored remotely in an Azure Storage blob
container (see [backend.tf](backend.tf)). Before running `init` for the
first time in a new environment, create the backend resources with the
bootstrap script:

```bash
./scripts/bootstrap-tfstate.sh
```

This creates:

- A resource group (default `rg-tfstate`)
- A storage account with versioning, soft delete (30 days), and TLS 1.2
  minimum enforced (default name `sttfstate<random-suffix>`)
- A blob container (default `tfstate`)

Configuration is via environment variables (all optional):

| Variable                | Default                    |
| ------------------------ | --------------------------- |
| `RESOURCE_GROUP_NAME`    | `rg-tfstate`                |
| `LOCATION`               | `northcentralus`            |
| `STORAGE_ACCOUNT_NAME`   | `sttfstate<random-suffix>`  |
| `CONTAINER_NAME`         | `tfstate`                   |

The script prints the `backend "azurerm" { ... }` block to paste into
[backend.tf](backend.tf) once it finishes — update that file to match the
resources it created before running `init`.

## Configuring variables

Copy the example tfvars file and fill in values for your environment:

```bash
cp terrraform.tfvars.example terraform.tfvars
```

Required variables (see [variables.tf](variables.tf)):

| Variable        | Description                                   | Default             |
| --------------- | ---------------------------------------------- | -------------------- |
| `location`      | Azure region                                   | *(required)*         |
| `product_name`  | Product name, used to derive resource names    | `Foundry Playground` |
| `standard_tags` | Map of tags applied to all resources           | *(required)*         |

`terraform.tfvars` is not committed to version control — each engineer/environment
maintains their own copy.

## Commands

### OpenTofu

```bash
tofu init
tofu plan
tofu apply
tofu destroy
```

### Terraform

```bash
terraform init
terraform plan
terraform apply
terraform destroy
```

## Project layout

| File                              | Purpose                                       |
| ---------------------------------- | ---------------------------------------------- |
| [main.tf](main.tf)                 | Provider config and resources                  |
| [variables.tf](variables.tf)       | Input variable declarations                    |
| [outputs.tf](outputs.tf)           | Output values                                  |
| [backend.tf](backend.tf)           | Remote state backend configuration             |
| [terraform.tfvars](terraform.tfvars) | Local variable values (gitignored)          |
| [terrraform.tfvars.example](terrraform.tfvars.example) | Example variable values     |
| [scripts/bootstrap-tfstate.sh](scripts/bootstrap-tfstate.sh) | One-time remote state bootstrap |
| [.terraform-version](.terraform-version) | Terraform version pin for tfenv          |
| [.opentofu-version](.opentofu-version)   | OpenTofu version pin for tofuenv         |
