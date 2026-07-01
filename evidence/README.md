# Validation Evidence

This directory is reserved for sanitized proof that implemented architecture components have been deployed and tested.

Architecture diagrams and Terraform definitions are not sufficient evidence by themselves. Each implemented requirement should be supported by test output, logs, metrics, screenshots, checksums, playback results, or another repeatable record.

## Confidentiality Rules

Before committing evidence, remove or mask:

- AWS account IDs
- Client or company names
- Email addresses and usernames
- Public IP addresses
- Private network ranges where sensitive
- Domain names and endpoint URLs
- S3 bucket names
- CloudFront distribution identifiers
- Resource ARNs
- Access keys, tokens, cookies, and secrets
- Production media or client data

Use sample media and development resources only.

## Planned Directory Structure

```text
evidence/
├── deployment/       # Terraform, deployment, and cleanup evidence
├── validation/       # Functional and negative test results
├── security/         # Access-denial, IAM, encryption, and control tests
├── playback/         # CloudFront and media playback results
├── monitoring/       # Logs, dashboards, alarms, and failure evidence
└── cost/             # Cost estimate and budget evidence
```

Directories should be added only when evidence exists. Empty directories are not required.

## Evidence Index Template

| Evidence ID | Requirement or control | Test | Expected result | Actual result | Status | Evidence path |
| --- | --- | --- | --- | --- | --- | --- |
| EVD-001 | Example: private S3 origin | Request object directly from S3 | Access denied | Pending | Not run | Pending |

## Minimum Proof-of-Concept Evidence

The first VOD vertical slice should produce evidence for:

1. Terraform formatting and validation
2. Terraform plan review
3. Successful development deployment
4. Upload event initiation
5. Step Functions successful execution
6. Metadata or processing-status update
7. Processed object creation
8. CloudFront delivery
9. Direct S3 access denial
10. Invalid input or forced workflow failure
11. SQS or dead-letter queue handling
12. CloudWatch logs and alarm behaviour
13. Cost estimate
14. Successful Terraform destruction

## Evidence Quality Standard

Each evidence item should include:

- Date
- Environment
- Test identifier
- Requirement or control being tested
- Preconditions
- Test procedure
- Expected result
- Actual result
- Pass or fail status
- Sanitized supporting artifact
- Follow-up action for failures

Do not mark a control as validated when only a configuration screenshot exists. Where practical, include a behavioural test showing that the control permits the intended action and denies the unintended action.
