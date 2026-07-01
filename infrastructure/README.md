# Infrastructure as Code

## Current Status

The deployable Infrastructure as Code implementation has not yet been added. This directory defines the intended Terraform structure and the requirements that future infrastructure code must satisfy.

No production-ready deployment is claimed until the Terraform configuration can be initialized, validated, planned, applied, tested, and destroyed successfully in a development AWS environment.

## Chosen Direction

Terraform is the planned primary Infrastructure as Code tool for the portfolio proof of concept. CloudFormation may be discussed as an alternative, but deployment instructions should not present both tools as interchangeable implementations unless both are actually maintained and tested.

## Planned Structure

```text
infrastructure/
├── README.md
├── versions.tf
├── providers.tf
├── variables.tf
├── outputs.tf
├── main.tf
├── modules/
│   ├── storage/
│   ├── vod-workflow/
│   ├── metadata/
│   ├── delivery/
│   ├── monitoring/
│   └── security/
└── environments/
    └── dev/
        ├── backend.tf.example
        └── dev.tfvars.example
```

## First Implementation Scope

The first deployable vertical slice should include:

- Private S3 ingest bucket
- Private S3 processed-content bucket
- S3 encryption, versioning, lifecycle rules, and Block Public Access
- CloudFront distribution and Origin Access Control
- DynamoDB processing-status table
- Event-driven workflow trigger
- Step Functions workflow
- SQS queue and dead-letter queue
- Lambda functions where required
- CloudWatch log groups and alarms
- Least-privilege IAM roles
- Standard project and cost-allocation tags

MediaLive and MediaPackage are intentionally excluded from the first implementation increment to keep the proof of concept affordable and repeatable.

## Required Tooling

The implementation should pin and document:

- Terraform version
- AWS provider version
- AWS CLI version used for testing
- TFLint version
- Checkov or tfsec version

## Planned Commands

```bash
terraform fmt -check
terraform init
terraform validate
terraform plan -var-file=environments/dev/dev.tfvars
terraform apply -var-file=environments/dev/dev.tfvars
```

After evidence has been collected:

```bash
terraform destroy -var-file=environments/dev/dev.tfvars
```

These commands are examples until the corresponding files exist.

## Configuration Rules

- Do not commit AWS credentials.
- Do not commit client data or production values.
- Provide `.tfvars.example` files containing non-sensitive sample values.
- Mark sensitive outputs appropriately.
- Use least-privilege IAM policies.
- Enable S3 Block Public Access.
- Encrypt supported data stores.
- Apply consistent project, environment, owner, and cost tags.
- Define log retention rather than retaining all logs indefinitely.
- Include cleanup instructions for every billable service.

## State Management

The first local development increment may use local state only when clearly documented and excluded from version control.

Before collaborative or production-like use, document and implement a protected remote-state strategy, including:

- Encrypted state storage
- State locking where supported
- Restricted access
- Versioning or recovery controls
- Separation between environments

## Required Outputs

The first implementation should expose only non-sensitive values required for validation, such as:

- Development CloudFront domain
- Ingest bucket identifier
- Processed-content bucket identifier
- DynamoDB table name
- Step Functions state-machine identifier
- Queue and dead-letter queue identifiers
- Dashboard name

Account IDs, credentials, secrets, and sensitive endpoints must not be displayed unnecessarily.

## Definition of Done

Infrastructure is considered ready for the first portfolio milestone when:

1. `terraform fmt -check` passes.
2. `terraform init` succeeds.
3. `terraform validate` passes.
4. Security scanning has no unresolved critical finding.
5. A plan can be reviewed without secrets or client data.
6. A development deployment succeeds.
7. Positive and negative validation tests pass.
8. Sanitized evidence is added under `evidence/`.
9. `terraform destroy` removes the test resources successfully.
10. The README deployment section is updated with tested commands and prerequisites.
