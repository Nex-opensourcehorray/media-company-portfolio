# Media Streaming Platform: On-Premises-to-AWS Migration Architecture

> **Confidentiality notice:** Client-identifying information, account details, environment values, media volumes, and sensitive operational data have been anonymized or omitted.

## Project Overview

This portfolio project presents the proposed migration of an on-premises media platform to Amazon Web Services. The target architecture supports authenticated application access, live streaming, Video on Demand (VOD), subtitle transcription and translation, private media origins, global content delivery, centralized monitoring, and security governance.

The design uses managed and serverless AWS services to reduce infrastructure-management overhead and improve resilience, scalability, observability, and operational consistency.

## Project Status

| Area | Status | Evidence in this repository |
| --- | --- | --- |
| Current-state assessment | Complete | Current-state diagram and risk analysis |
| Target AWS architecture | Complete | Overall and functional-flow diagrams |
| Business and service mapping | Complete | Availability, scalability, cost, operations, and security mapping |
| Migration planning | Draft complete | `docs/MIGRATION_PLAN.md` |
| Security standard | Draft complete | `docs/SECURITY.md` |
| Validation planning | Draft complete | `docs/VALIDATION.md` |
| Production runbook | Draft complete | `docs/RUNBOOK.md` |
| Infrastructure as Code | Planned | Structure and implementation roadmap only |
| Proof-of-concept deployment | Planned | No production deployment is claimed |
| Validation evidence | Planned | Evidence structure prepared for future test results |
| Client production migration | Not represented publicly | Excluded or anonymized for confidentiality |

**Important:** This repository currently demonstrates architecture, migration, security, and operational planning. It does not yet claim that the complete target platform has been deployed to production.

## My Contribution

The work represented in this repository includes:

- Current-state architecture assessment and risk identification
- Business and non-functional requirement analysis
- AWS service selection and architecture design
- Live-stream, VOD, subtitle, delivery, and security flow decomposition
- Migration-phase planning and rollback design
- Security, monitoring, governance, and recovery planning
- Validation criteria and production runbook preparation
- Portfolio documentation and architecture-diagram development

## Business Objectives

The migration is intended to:

1. Improve platform availability and resilience.
2. Support uncertain and rapidly changing audience demand.
3. Reduce manual infrastructure administration.
4. Optimize media storage, processing, and delivery costs.
5. Strengthen security, monitoring, auditing, and governance.
6. Provide globally distributed, low-latency content delivery.
7. Establish repeatable deployment and change-control practices.

## Current-State Summary

The existing environment is centered on a single cache-enabled on-premises application server connected to Amazon S3 for persistent and incremental storage.

The centralized design introduces several risks:

- Single point of failure
- Limited horizontal scalability
- CPU, memory, disk, and network contention
- Volatile in-memory data
- Synchronization risk between local cache and S3
- Internet dependency for backup and retrieval
- Manual infrastructure maintenance and recovery

The current environment supports seven known client endpoints. Because the precise business role and future scale of these clients are confidential or not yet fully confirmed, the target design treats future viewer demand and media-processing demand as variable rather than assuming that the current count represents the final audience size.

![Current on-premises architecture](./architecture/Receive_Note.png)

## Target-State AWS Architecture

### Overall Architecture

![Target-State AWS Media Platform — Overall Architecture](./architecture/Target-State_AWS_Media_Platform%20-%20Overall_Architecture.svg)

The target platform separates application access, media processing, subtitle processing, content delivery, and cross-cutting security controls.

### Functional Flow Decomposition

![Target-State AWS Media Platform — Functional Flow Decomposition](./architecture/Target-State_AWS_Media_Platform%20-%20Functional_Flow_Decomposition.svg)

| Flow | Function | Primary AWS services |
| --- | --- | --- |
| F1 | Authentication and application API | Route 53, API Gateway, AWS WAF, Cognito, Lambda, DynamoDB |
| F2 | Live-stream processing | MediaLive, Transcribe Live, Translate, MediaPackage |
| F3 | VOD processing | S3, EventBridge, Step Functions, Lambda, SQS, MediaConvert |
| F4 | Subtitle processing | Transcribe, Translate, S3, DynamoDB |
| F5 | Content delivery | CloudFront, MediaPackage, S3, Origin Access Control |
| F6 | Security and monitoring | WAF, KMS, Firewall Manager, CloudWatch, CloudTrail, Config, GuardDuty |

## Business Criteria and AWS Service Mapping

### Availability and Resilience

The proposed platform targets at least 99.9% availability, subject to final agreement on the measurement scope and service-level indicators.

Key design choices include:

- MediaLive Standard channels for redundant live-processing pipelines
- MediaPackage as a managed live origin and packaging layer
- Amazon S3 for durable VOD, subtitle, and supporting assets
- CloudFront for distributed delivery and origin-load reduction
- Route 53 health-based or failover routing where required

### Scalability

Because the final viewer and request profile is not yet confirmed, the design favors elastic and consumption-based services:

- CloudFront for globally distributed viewer traffic
- API Gateway for managed application APIs
- Lambda for event-driven backend functions
- DynamoDB On-Demand for initially uncertain access patterns
- Managed AWS media services for workload-specific scaling

### Cost Optimization

The proposed controls include:

- S3 lifecycle and retention policies
- CloudFront caching
- Lambda and API Gateway request-based pricing
- MediaConvert job-based transcoding
- DynamoDB On-Demand during early traffic uncertainty
- AWS Budgets, Cost Explorer, tagging, and cost-allocation controls

A documented cost estimate is still required before any production deployment.

### Operational Excellence

The target design uses:

- EventBridge, Step Functions, Lambda, and S3 events for workflow automation
- CloudWatch metrics, logs, dashboards, and alarms
- CloudTrail for API auditing
- AWS Config for configuration tracking
- Version-controlled Infrastructure as Code
- Documented validation, cutover, recovery, and rollback procedures

### Security and Governance

The proposed security model includes:

- Least-privilege IAM roles and temporary credentials
- MFA for privileged users
- KMS-backed encryption where supported
- TLS 1.2 or later for data in transit
- S3 Block Public Access and CloudFront Origin Access Control
- WAF and Shield protections for supported public entry points
- Signed CloudFront URLs, signed cookies, or short-lived playback tokens where required
- Secrets Manager or Systems Manager Parameter Store for sensitive configuration
- CloudTrail, Config, CloudWatch, WAF logs, and GuardDuty
- Production and non-production environment separation
- Peer-reviewed and version-controlled infrastructure changes

See [`docs/SECURITY.md`](./docs/SECURITY.md) for the detailed draft control standard.

## Migration Approach

The proposed migration combines **re-platforming**, **refactoring**, and controlled data migration.

### Principal transitions

- Live encoding and packaging move toward MediaLive and MediaPackage.
- VOD processing becomes an event-driven workflow using S3, EventBridge, Step Functions, Lambda, SQS, and MediaConvert.
- Media assets move to private S3 buckets with lifecycle controls.
- Metadata and processing status move to DynamoDB or another confirmed target database.
- Application APIs move toward API Gateway and Lambda.
- Subtitle generation uses Transcribe, Translate, Lambda, S3, and metadata mappings.
- Content delivery moves to CloudFront.

### Migration phases

1. Discovery and assessment
2. AWS foundation and landing zone
3. Pilot migration
4. Media and metadata migration
5. Application and workflow migration
6. Production cutover
7. Stabilization and optimization

The detailed phase plan, deliverables, assumptions, exit criteria, cutover controls, and rollback procedures are maintained in [`docs/MIGRATION_PLAN.md`](./docs/MIGRATION_PLAN.md).

## Non-Functional Requirements and Open Decisions

Some requirements remain confidential, unmeasured, or pending confirmation.

| Requirement | Current treatment |
| --- | --- |
| Availability target | 99.9% proposed; measurement scope must be confirmed |
| Primary AWS Region | Pending confirmation |
| Recovery Region | Pending confirmation |
| Peak concurrent viewers | Confidential or pending measurement |
| Media volume and growth | Confidential or pending measurement |
| Supported codecs and resolutions | Pending confirmation |
| Live input protocol | Pending confirmation |
| Subtitle languages | Pending confirmation |
| RTO and RPO | Pending approval |
| Cutover window | Pending approval |
| Monthly budget threshold | Pending approval |

These are not hidden implementation claims. They are documented design dependencies that must be resolved before production readiness can be asserted.

## Validation Strategy

The project uses evidence-based acceptance. A service or control is not considered validated merely because it appears in a diagram or template.

Future proof-of-concept validation should collect:

- Terraform validation and plan output
- Successful deployment records
- Step Functions execution history
- MediaConvert processing results
- CloudFront playback results
- Direct S3 access-denied tests
- Authentication and authorization tests
- SQS dead-letter queue tests
- CloudWatch alarm evidence
- Object counts and checksums
- Cost estimates and budget checks
- Cleanup or destruction confirmation

See [`docs/VALIDATION.md`](./docs/VALIDATION.md) and [`evidence/README.md`](./evidence/README.md).

## Recommended Proof-of-Concept Scope

The first deployable increment should focus on one complete VOD vertical slice:

1. Upload a sample video to a private ingest bucket.
2. Trigger an event-driven workflow.
3. Orchestrate processing with Step Functions.
4. Use SQS and a dead-letter queue for controlled failure handling.
5. Produce processed output with MediaConvert or a documented lower-cost test substitute.
6. Publish output to a private S3 origin.
7. Deliver content through CloudFront with Origin Access Control.
8. Record processing status in DynamoDB.
9. Generate CloudWatch logs and alarms.
10. Deploy and destroy the environment through Terraform.

Live-stream services can remain architecture-only until the VOD slice has repeatable deployment and validation evidence.

## Repository Structure

```text
.
├── architecture/                  # Current-state and target-state diagrams
├── docs/
│   ├── MIGRATION_PLAN.md          # Detailed migration journey
│   ├── RUNBOOK.md                 # Draft deployment, cutover, and rollback procedures
│   ├── SECURITY.md                # Draft security control standard
│   ├── VALIDATION.md              # Draft test and acceptance plan
│   └── PORTFOLIO_ROADMAP.md       # Incremental implementation roadmap
├── evidence/
│   └── README.md                  # Evidence collection structure
├── infrastructure/
│   └── README.md                  # Planned Terraform structure and deployment contract
└── README.md                      # Portfolio landing page
```

## Deployment Status

A complete deployable Terraform or CloudFormation implementation is **not yet published in this repository**. Therefore, no production-ready deployment command is currently claimed.

The planned Terraform workflow is:

```bash
terraform fmt -check
terraform init
terraform validate
terraform plan -var-file=environments/dev/dev.tfvars
terraform apply -var-file=environments/dev/dev.tfvars
```

After validation, the test environment should be removed to prevent continuing cloud charges:

```bash
terraform destroy -var-file=environments/dev/dev.tfvars
```

These commands become authoritative only after the Terraform files, variables, provider constraints, state strategy, and environment configuration are implemented.

## Completion Criteria

This portfolio project should be considered implementation-complete only when:

- A documented Terraform vertical slice can be deployed repeatedly.
- Automated formatting, validation, linting, and security checks pass.
- Positive and negative validation tests are recorded.
- Private S3 origins cannot be accessed directly.
- Workflow failures reach an observable and recoverable failure path.
- Monitoring and alarm behaviour is demonstrated.
- Estimated costs are documented.
- Cleanup instructions work successfully.
- Draft documents contain final dates, owners, versions, and statuses.
- The README clearly distinguishes implemented, proposed, confidential, and out-of-scope components.

## Roadmap

Implementation is organized into incremental, reviewable steps in [`docs/PORTFOLIO_ROADMAP.md`](./docs/PORTFOLIO_ROADMAP.md).

The next engineering milestone is the Terraform-based VOD proof of concept, followed by test evidence, CI checks, security hardening, and optional live-stream expansion.
