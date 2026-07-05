# AGENTS.md

Guidance for AI coding agents working in this repository.

## Project

Terraform/OpenTofu configuration that provisions a Microsoft Foundry (Azure
AI Foundry) playground environment in Azure. Currently provisions a resource
group; a Key Vault, Application Insights, Storage Account, Virtual Network,
Azure AI Foundry account, Log Analytics workspace, and AI Foundry project are
planned (see the comment block at the bottom of [main.tf](main.tf)).

Provider: `azurerm` (`~> 4.80`). Compatible with both Terraform and OpenTofu.

## Tooling and version pinning

- [.terraform-version](.terraform-version) pins the Terraform version for [tfenv](https://github.com/tfutils/tfenv)
- [.opentofu-version](.opentofu-version) pins the OpenTofu version for [tofuenv](https://github.com/tofuutils/tofuenv)

Run `tfenv use` or `tofuenv use` before running any Terraform/OpenTofu
commands so the correct binary version is on `PATH`.

## Remote state

State is stored remotely in Azure Blob Storage, configured in
[backend.tf](backend.tf). The backend resources (resource group, storage
account, container) are not created by this Terraform config itself — they
must exist first, created via [scripts/bootstrap-tfstate.sh](scripts/bootstrap-tfstate.sh).

Do not run this script automatically. It creates real Azure resources and
requires interactive confirmation (owner tag input, a y/N prompt) and Azure
CLI authentication (`az login`). Only run it when a user explicitly asks to
bootstrap or re-bootstrap remote state, and only after confirming the target
subscription/tenant is correct.

If the script's output backend block differs from [backend.tf](backend.tf),
update `backend.tf` to match, then run `init` (with `-migrate-state` if state
already exists locally).

## Variables

[variables.tf](variables.tf) declares `location`, `product_name`, and
`standard_tags`. Values are supplied via `terraform.tfvars` (gitignored, one
per environment/engineer). [terrraform.tfvars.example](terrraform.tfvars.example)
(note the filename typo — preserve it, don't "fix" it, since it's the
existing example file agents and users copy from) shows the expected shape.

Do not commit real `terraform.tfvars` values or invent tag values (e.g.
`Owner`) — ask the user or read their existing `terraform.tfvars` if present.

## Commands

Prefer whichever binary the user has installed/active; both are supported
identically since the config has no tool-specific syntax.

```bash
# OpenTofu
tofu init
tofu plan
tofu apply
tofu destroy

# Terraform
terraform init
terraform plan
terraform apply
terraform destroy
```

## Safety notes for agents

- `apply` and `destroy` change real Azure infrastructure and cost money.
  Always show the user the `plan` output and get explicit confirmation
  before running `apply` or `destroy`.
- Never run `apply`/`destroy` with `-auto-approve` unless the user explicitly
  requests it.
- Never run `bootstrap-tfstate.sh` without explicit user request — it
  provisions a new storage account and resource group.
- Do not edit `.terraform.lock.hcl` by hand; regenerate it with
  `init -upgrade` if a provider version changes.
- `terraform.tfvars` may contain environment-specific values (owner, region);
  treat it as local configuration, not something to template away.
