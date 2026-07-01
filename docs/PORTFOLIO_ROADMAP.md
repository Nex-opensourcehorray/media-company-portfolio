# Portfolio Implementation Roadmap

## Purpose

This roadmap converts the architecture and migration documentation into a demonstrable cloud-engineering portfolio project. Work is intentionally divided into small, reviewable increments so that each stage adds verifiable evidence rather than expanding the design without implementation proof.

## Current Baseline

The repository currently includes:

- Current-state and target-state architecture diagrams
- Business criteria and AWS service mapping
- A migration plan
- A production runbook draft
- A security standard draft
- A validation plan draft

The repository does not yet claim a complete AWS deployment.

## Step 1 — Portfolio Positioning and Repository Structure

**Status:** In progress in the first documentation PR.

Deliverables:

- Concise portfolio README
- Clear project status and contribution statement
- Explicit separation of implemented, proposed, confidential, and out-of-scope work
- Evidence directory structure
- Infrastructure directory contract
- Correct repository navigation and deployment-status wording

Exit criteria:

- No unfinished deployment placeholder remains in the README.
- The README does not imply that unimplemented infrastructure has been deployed.
- A recruiter can understand the project scope within the first page.

## Step 2 — Terraform Foundation

Deliverables:

- Terraform version and AWS provider constraints
- Remote-state decision documented
- Naming and tagging convention
- Development environment variables
- Secure sample variable file without credentials
- Reusable module structure
- Outputs required for testing

Suggested structure:

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

Exit criteria:

- `terraform fmt -check` passes.
- `terraform init` succeeds.
- `terraform validate` passes.
- No credentials or client-sensitive values are committed.

## Step 3 — Private Storage and Content Delivery

Deliverables:

- Private ingest bucket
- Private processed-content bucket
- S3 Block Public Access
- Encryption and versioning configuration
- Lifecycle rules for temporary and processed assets
- CloudFront distribution
- CloudFront Origin Access Control
- Bucket policy permitting only approved CloudFront access

Validation:

- Direct unauthenticated S3 access is denied.
- CloudFront can retrieve the approved object.
- Encryption, versioning, and lifecycle configuration are visible in Terraform output or AWS evidence.

## Step 4 — Event-Driven VOD Workflow

Deliverables:

- Ingest event routing
- Step Functions state machine
- Processing Lambda functions where required
- SQS queue and dead-letter queue
- MediaConvert integration or a clearly documented lower-cost development substitute
- DynamoDB table for processing status and metadata
- Idempotency and duplicate-event handling

Validation:

- Valid upload starts one workflow.
- Successful processing updates metadata and publishes output.
- Invalid input follows a controlled failure path.
- Repeated events do not create uncontrolled duplicate processing.
- Failed messages can be identified and recovered.

## Step 5 — Monitoring and Security Controls

Deliverables:

- CloudWatch log groups with retention
- CloudWatch dashboard
- Alarms for workflow failures, queue depth, Lambda errors, and processing failures
- CloudTrail and configuration-monitoring decisions
- Least-privilege IAM roles
- KMS and secrets-management decisions
- Security test cases

Validation:

- A forced workflow failure triggers logs and an alarm.
- IAM policies are scoped to required resources.
- Sensitive values are not stored in source code or Terraform state without documented protection.

## Step 6 — Automated Quality Checks

Deliverables:

- GitHub Actions workflow
- Terraform formatting and validation
- TFLint
- Checkov or tfsec
- Markdown-link checking
- Secret scanning
- Unit tests for Lambda code where applicable

Exit criteria:

- Pull requests show automated pass/fail results.
- Security findings are resolved, accepted with justification, or documented as non-applicable.

## Step 7 — Evidence Collection

Deliverables:

- Sanitized deployment evidence
- Terraform plan summary
- Successful workflow execution
- Failure and dead-letter tests
- CloudFront playback evidence
- Direct-origin denial evidence
- Monitoring and alarm evidence
- Object-count and checksum results
- Cost estimate
- Destruction and cleanup evidence

Exit criteria:

- Every implemented requirement maps to at least one evidence item.
- Screenshots and logs contain no account IDs, client names, secrets, or sensitive endpoints.

## Step 8 — Documentation Finalization

Deliverables:

- Replace `YYYY-MM-DD` metadata
- Set accurate document statuses
- Resolve or classify each `TBD`
- Add Architecture Decision Records
- Add threat model and trust-boundary documentation
- Record known limitations
- Record measured proof-of-concept results

Recommended decision records:

- DynamoDB versus relational storage
- Step Functions versus direct Lambda orchestration
- CloudFront signed URLs versus signed cookies
- MediaConvert versus development substitute
- Single-Region versus multi-Region
- DynamoDB On-Demand versus provisioned capacity

## Step 9 — Optional Live-Streaming Expansion

This stage should begin only after the VOD vertical slice is repeatable and validated.

Potential deliverables:

- MediaLive Standard channel design or controlled deployment
- MediaPackage origin
- Live transcription and translation testing
- Input-loss and failover validation
- Live playback and latency evidence
- Cost controls for temporary testing

Because managed live-media services may create significant cost, deployment must include explicit start, stop, and cleanup procedures.

## Definition of Done

The portfolio is considered technically complete when it demonstrates:

1. Repeatable Infrastructure as Code deployment.
2. A complete event-driven media-processing vertical slice.
3. Private content origin with controlled delivery.
4. Positive and negative tests.
5. Observable failure handling.
6. Automated repository checks.
7. Sanitized implementation evidence.
8. Documented cost and cleanup procedures.
9. Accurate project-status statements.
10. Clear limitations and confidentiality boundaries.
