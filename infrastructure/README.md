# Infrastructure as Code

## Current Status

Step 2 introduces a real Terraform foundation and the first deployable infrastructure slice:

- Private S3 ingest bucket
- Private S3 processed-content bucket
- S3 Block Public Access
- Bucket-owner-enforced object ownership
- SSE-S3 encryption
- Versioning
- Ingest expiration and processed-content lifecycle rules
- CloudFront distribution
- CloudFront Origin Access Control
- Processed-bucket policy restricted to the specific CloudFront distribution
- Default project and environment tags
- Validated input variables
- Non-sensitive outputs for testing
- Development variable and remote-state examples
- GitHub Actions formatting and validation workflow

This code has not yet been applied to an AWS account. Production readiness is not claimed until it has been initialized, planned, deployed, tested, evidenced, and destroyed successfully in a development environment.

## Implemented Structure

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
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── delivery/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── environments/
    └── dev/
        ├── backend.tf.example
        └── dev.tfvars.example
```

## Requirements

- Terraform `>= 1.6.0, < 2.0.0`
- AWS provider `>= 5.80.0, < 7.0.0`
- AWS credentials supplied through an approved mechanism such as AWS IAM Identity Center, an assumed role, or environment-based credentials
- Permission to create S3 buckets, S3 policies, CloudFront resources, and associated read-only identity data

Do not place access keys, client data, production values, or secrets in Terraform files or variable files.

## Development Deployment

Copy the sample variable file:

```bash
cd infrastructure
cp environments/dev/dev.tfvars.example environments/dev/dev.tfvars
```

Review the values before proceeding. The example enables `force_destroy = true` for disposable development testing only.

Format and initialize:

```bash
terraform fmt -recursive
terraform init
terraform validate
```

Create and review a saved plan:

```bash
terraform plan \
  -var-file=environments/dev/dev.tfvars \
  -out=dev.tfplan
```

Apply only after reviewing the complete plan:

```bash
terraform apply dev.tfplan
```

Retrieve validation outputs:

```bash
terraform output
```

## Initial Validation

After deployment, use sample content only.

1. Upload a non-sensitive test object to the processed bucket.
2. Request the object through the `cloudfront_url` output.
3. Confirm that the CloudFront request succeeds after distribution propagation.
4. Attempt direct unauthenticated access to the S3 object URL.
5. Confirm that direct S3 access is denied.
6. Record sanitized evidence under `evidence/`.

The ingest bucket is not connected to a processing workflow in Step 2. Event routing, Step Functions, SQS, Lambda, MediaConvert, and DynamoDB belong to later implementation steps.

## Cleanup

CloudFront distributions can take time to disable and delete. Remove test objects before destruction when `force_destroy` is false.

```bash
terraform destroy -var-file=environments/dev/dev.tfvars
```

Confirm that the following have been removed:

- Ingest bucket
- Processed-content bucket
- Processed-bucket policy
- CloudFront distribution
- CloudFront Origin Access Control

## State Management

Local state may be used only for a controlled individual development exercise and must not be committed.

`environments/dev/backend.tf.example` documents the expected remote-state direction. Before collaborative or production-like use, create a dedicated protected state backend with:

- Encryption
- Restricted access
- State recovery or versioning
- Locking
- Environment separation

The media buckets created by this project must not be reused as the Terraform state bucket.

## Security Decisions in Step 2

- Both buckets block all forms of public access.
- ACLs are disabled through `BucketOwnerEnforced` ownership controls.
- Objects are encrypted at rest using SSE-S3.
- CloudFront signs origin requests with Signature Version 4.
- The processed bucket policy permits `s3:GetObject` only when the request comes from the exact CloudFront distribution ARN.
- The ingest bucket has no public or CloudFront read policy.
- HTTP viewers are redirected to HTTPS.
- The AWS-managed optimized cache policy and security-header response policy are used.

Customer-managed KMS keys, signed viewer URLs or cookies, WAF, logging, and security scanning remain later hardening steps.

## Current Outputs

- AWS account ID
- AWS Region
- Ingest bucket name
- Processed-content bucket name
- CloudFront distribution ID
- CloudFront domain name
- CloudFront HTTPS base URL

These outputs contain no credentials or secrets. Account and resource identifiers should still be sanitized before publishing screenshots.

## CI Validation

`.github/workflows/terraform-validate.yml` runs:

```bash
terraform fmt -check -recursive
terraform init -backend=false -input=false
terraform validate -no-color
```

The workflow does not deploy AWS resources and does not require AWS credentials.

## Step 2 Exit Criteria

Step 2 is complete when:

1. The GitHub Actions formatting and validation job passes.
2. A reviewer confirms that no credential or client-sensitive value is present.
3. The Terraform plan is reviewed in a development account.
4. The private-origin test succeeds.
5. Direct S3 object access is denied.
6. The environment can be destroyed successfully.
7. Sanitized validation evidence is recorded.

Items 3-7 require an AWS development deployment and remain unverified until that deployment is performed.
