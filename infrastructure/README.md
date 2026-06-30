# Terraform Infrastructure

This directory converts the target-state AWS architecture into a modular Terraform layout. The modules follow the functional flows documented in the main project README and migration plan.

## Folder map

```text
infrastructure/
├── README.md
├── .gitignore
├── bootstrap/
│   └── main.tf
├── environments/
│   ├── dev/
│   │   └── main.tf
│   ├── staging/
│   │   └── main.tf
│   └── prod/
│       └── main.tf
└── modules/
    ├── shared-foundation/
    │   └── main.tf
    ├── f1-auth-api/
    │   └── main.tf
    ├── f2-live-stream/
    │   └── main.tf
    ├── f3-vod-processing/
    │   └── main.tf
    ├── f4-subtitle-processing/
    │   └── main.tf
    ├── f5-content-delivery/
    │   └── main.tf
    └── f6-security-observability/
        └── main.tf
```

## Flow ownership

| Module | Architecture flow | Intended AWS services |
| --- | --- | --- |
| `shared-foundation` | Shared platform foundation | Naming, tags, Route 53 inputs, shared KMS references, account/region context |
| `f1-auth-api` | F1 Authentication and application API | Cognito, API Gateway, Lambda, DynamoDB, WAF association |
| `f2-live-stream` | F2 Live-stream processing | MediaLive, MediaPackage, live Transcribe/Translate integration points |
| `f3-vod-processing` | F3 VOD processing | S3 ingest, EventBridge, Step Functions, SQS/DLQ, MediaConvert |
| `f4-subtitle-processing` | F4 Subtitle processing | Transcribe, Translate, S3 subtitle storage, DynamoDB mappings |
| `f5-content-delivery` | F5 Content delivery | CloudFront, S3 origins, MediaPackage origin, Origin Access Control, signed access |
| `f6-security-observability` | F6 Security and monitoring | KMS, CloudTrail, Config, GuardDuty, CloudWatch, WAF and governance integration |

## Environment model

Each environment is a Terraform root module and composes the shared and F1-F6 child modules. Keep state isolated by environment and use separate AWS accounts where possible.

Recommended state keys:

```text
media-platform/dev/terraform.tfstate
media-platform/staging/terraform.tfstate
media-platform/prod/terraform.tfstate
```

The `bootstrap` root is intentionally separate because the remote-state bucket and lock table must exist before the environment roots can use them.

## Implementation order

1. Bootstrap encrypted remote state and locking.
2. Implement `shared-foundation` naming, tags and common controls.
3. Implement F3 and F5 first for a small VOD pilot.
4. Add F1 playback authorization and metadata APIs.
5. Add F4 subtitle automation.
6. Add F2 live-stream processing after quotas, input protocols and redundancy requirements are confirmed.
7. Implement F6 controls continuously across every flow rather than treating security as a final phase.

## Local workflow

Run Terraform from an environment directory:

```bash
cd infrastructure/environments/dev
terraform fmt -recursive ../../
terraform init
terraform validate
terraform plan
```

Do not commit `.terraform/`, state files, plans, credentials, secrets, media assets or generated Lambda packages.

## Current scope

This commit establishes the module boundaries, dependency direction and environment roots. Resource implementations remain intentionally incomplete until the primary Region, recovery requirements, media formats, traffic assumptions, quotas, RTO/RPO and budget thresholds are confirmed.
