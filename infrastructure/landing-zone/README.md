# AWS Multi-Account Landing Zone

This directory adds a Terraform scaffold for separating organization governance, centralized Terraform tooling, security operations, log retention, and workload environments.

## Account model

| Account | Purpose |
| --- | --- |
| Management | AWS Organizations, organizational units, and service control policies only |
| Terraform tooling | Central remote state and the deployment principal used by CI/CD |
| Security tooling | Delegated security administration and security-operations integrations |
| Log archive | Immutable or tightly controlled organization-wide audit-log retention |
| Development | Non-production media-platform workloads |
| Staging | Pre-production validation and release testing |
| Production | Production media-platform workloads and data |

## Structure

```text
landing-zone/
├── README.md
├── bootstrap-account/
├── organization/
├── accounts/
│   ├── terraform-tooling/
│   ├── workload/
│   ├── security-tooling/
│   └── log-archive/
└── modules/
    ├── deployment-role/
    ├── organization-guardrails/
    └── state-backend/
```

## Deployment sequence

1. Create or identify the AWS Organization, organizational units, and member accounts.
2. Deploy `accounts/terraform-tooling` with temporary administrator credentials to create the central state backend.
3. Run `bootstrap-account` once in every target account to create the delegated Terraform role.
4. Configure each account root with a partial S3 backend configuration and an account-specific state key.
5. Deploy organization guardrails from the management account only after testing policies in a non-production OU.
6. Deploy development, staging, and production from separate states and separate delegated roles.

## State isolation

Recommended keys:

```text
organization/terraform.tfstate
accounts/terraform-tooling/terraform.tfstate
accounts/security-tooling/terraform.tfstate
accounts/log-archive/terraform.tfstate
workloads/dev/terraform.tfstate
workloads/staging/terraform.tfstate
workloads/prod/terraform.tfstate
```

The backend uses S3 versioning, KMS encryption, and S3 lockfiles. Backend values remain in `.hcl` files or CI variables rather than being embedded in Terraform source.

## Safety model

- No account creation is attempted by default.
- No SCP is attached unless `enable_guardrails` is explicitly enabled.
- Workload providers enforce `allowed_account_ids`.
- Account roots assume a named deployment role rather than using long-lived administrator credentials.
- The deployment-role module grants no workload permissions unless policy ARNs or an inline policy are supplied.
- The management account should not host application workloads.
