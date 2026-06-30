# Interview Narrative: Security-First AWS Media Platform

## 60–90 second introduction

I designed a Terraform-based AWS multi-account reference architecture for a media platform. The main goal was to show how I would secure and operate a platform that includes video ingestion and transcoding, rather than building only the application resources.

I separated the environment into management, Terraform tooling, security tooling, log archive, development, staging, and production accounts. GitHub Actions authenticates through AWS OIDC, receives temporary credentials in the tooling account, and can assume only an explicit list of deployment roles. Security Hub and GuardDuty are delegated to a dedicated security account, while an organization-wide CloudTrail sends encrypted logs to a separate log-archive account with versioning, lifecycle retention, and optional Object Lock.

For the workload layer, I created a reusable composition model and implemented the most detailed application flow as an event-driven VOD pipeline using S3, EventBridge, Step Functions, MediaConvert, SQS, and CloudWatch. I also built a reusable security module with WAF, permission boundaries, Secrets Manager, KMS, and alarms.

The project is a reference architecture prototype rather than a claimed production deployment. I documented which modules contain substantive resources, which are scaffolds, and what validation and deployment evidence would still be required. That honesty is important because I want the architecture to be technically defensible, not just visually impressive.

---

## Three-minute STAR narrative

### Situation

I wanted to create a cloud-security portfolio project that was stronger than a single-account Terraform lab. A realistic media platform needs application services, but it also needs secure deployment identities, independent audit retention, centralized threat detection, environment isolation, and a controlled method for applying organization-wide changes.

### Task

My task was to design an AWS reference architecture that could support media ingestion and VOD processing while demonstrating multi-account governance, least privilege, centralized security, auditability, and reusable infrastructure-as-code.

### Action

I divided the design into separate trust boundaries:

- the management account owns AWS Organizations-level governance;
- the Terraform tooling account owns CI federation and state;
- the security tooling account is the delegated GuardDuty and Security Hub administrator;
- the log archive account owns CloudTrail storage and encryption;
- dev, staging, and production each host their own workload stack.

I replaced the idea of static GitHub secrets with an IAM OIDC provider. The GitHub orchestration role checks exact subject claims, can access only approved Terraform state prefixes, and can assume only allowlisted deployment roles.

For audit protection, I created a KMS-encrypted S3 log archive with versioning, lifecycle transitions, and optional Object Lock. I scoped the S3 and KMS policies to the expected CloudTrail source ARN. The organization-trail root also checks that the Region, trail name, partition, and management account match the values prepared by the log-archive module.

For security operations, I used delegated administration so the management account performs only the delegation, while the security account owns GuardDuty detectors, organization auto-enablement, Security Hub aggregation, central configuration, and policy associations.

For the media workload, I modelled an event-driven VOD pipeline where S3 object-created events are routed through EventBridge to Step Functions, which submits MediaConvert jobs. Failures are sent to SQS queues and surfaced through CloudWatch. A separate F6 module provides WAF, IAM permission boundaries, Secrets Manager integration, KMS, and security alarms.

I also documented implementation status carefully. F3, F6, and the landing-zone control plane contain the strongest Terraform implementation. F1, F2, F4, and F5 currently define interfaces and future boundaries. I did not represent the repository as deployed or production-certified.

### Result

The result is a portfolio-grade AWS reference architecture that demonstrates cloud-security design, Terraform modularity, cross-account IAM, centralized audit logging, delegated security administration, workload identity federation, and event-driven media processing.

The project also gave me a clear validation roadmap: complete provider validation, add gated plan/apply and drift workflows, deploy into a sandbox organization, capture operational evidence, and then implement the remaining application modules.

---

## Answer to “What was the hardest part?”

The hardest part was coordinating trust and dependencies across accounts without creating circular bootstrap assumptions.

The tooling account needs a state backend and OIDC role before normal CI/CD can run. Destination accounts need deployment roles before the tooling role can assume them. The organization trail needs a bucket and KMS policy in the log-archive account, but those policies must already know the expected trail ARN from the management account.

I solved this by separating the lifecycle into explicit stages:

1. bootstrap the central state and tooling account;
2. create delegated deployment roles in each destination account using temporary administrative access;
3. deploy the security and log-archive control planes;
4. enable delegated organization features only after prerequisites exist;
5. create the organization trail after validating the prepared bucket and KMS policy contract;
6. use OIDC and cross-account roles for normal operations.

That sequencing is as important as the Terraform resources themselves.

---

## Answer to “How did you apply least privilege?”

I applied least privilege at multiple layers instead of relying on one IAM policy:

- GitHub OIDC trust requires the correct audience and exact subject claims.
- The orchestration role can assume only explicit deployment-role ARNs.
- State permissions are restricted to named S3 prefixes and one KMS key.
- Workload providers enforce `allowed_account_ids`.
- Deployment roles can use an IAM permissions boundary.
- MediaConvert, Step Functions, and EventBridge use separate service roles.
- CloudTrail bucket and KMS policies are scoped to the expected trail source ARN.
- Audit readers are provided explicitly instead of granting organization-wide read access.

I would still validate the effective permissions with IAM Access Analyzer and policy simulation before production use.

---

## Answer to “Why separate the security and log-archive accounts?”

The two accounts serve different trust purposes.

The security account needs operational access to findings, policies, and detections. The log-archive account should be more restrictive because it protects evidence that may be needed during an investigation. Combining them would allow a compromised security operator or automation path to reach both the detection system and the evidence store.

Separating them supports separation of duties and makes it easier to apply stronger retention, access, and break-glass policies to audit logs.

---

## Answer to “Why OIDC instead of AWS access keys?”

OIDC lets GitHub Actions exchange a signed identity token for temporary AWS credentials. This removes the need to store long-lived AWS access keys in GitHub secrets.

The security value comes from the trust conditions. The role does not trust every GitHub workflow; it requires the `sts.amazonaws.com` audience and a configured set of exact subject claims. The resulting session is temporary and the role permissions are restricted to state access and approved cross-account roles.

---

## Answer to “What would you do before production?”

I would complete five gates:

1. Run formatting, initialization, validation, and security scanning for every module and root.
2. Fix and test the remaining F3 state-machine details against the pinned AWS provider.
3. Add PR plans, saved-plan approvals, environment-gated applies, and scheduled drift detection.
4. Deploy to a sandbox AWS Organization and capture evidence for CloudTrail delivery, KMS encryption, Object Lock behavior, Security Hub central policies, GuardDuty membership, and OIDC role sessions.
5. Perform IAM Access Analyzer reviews, failure testing, recovery testing, and cost analysis.

Only after those gates would I call the architecture production-ready.

---

## Answer to “What would you improve next?”

My next technical priorities would be:

- complete F1 with Cognito, API Gateway, Lambda, and DynamoDB;
- implement F2 live streaming with MediaLive and MediaPackage;
- implement F4 subtitle processing with Transcribe and Translate;
- implement F5 content delivery with CloudFront and an edge WAF design;
- add policy-as-code checks and automated documentation;
- add centralized alert routing from GuardDuty and Security Hub;
- add cost estimates and service quotas;
- test multi-Region recovery and log-delivery failure scenarios.

---

## Deep-dive questions to prepare for

### Why is the WAF regional rather than global?

The current F6 module models a regional WAF for regional resources such as API Gateway or an Application Load Balancer. A CloudFront distribution requires a WAF created in the CloudFront control Region and should be introduced with the F5 implementation.

### Does a permission boundary grant access?

No. A permissions boundary limits the maximum permissions that identity policies can grant. A role still needs an identity policy allowing the action, and other policy layers such as SCPs and resource policies can further restrict it.

### Why not store the application secret value in Terraform?

Terraform state may contain resource arguments. The module creates the secret metadata and access policy, but the plaintext value should be populated through a separate secure deployment or secret-rotation process.

### What is the risk of S3 Object Lock Compliance mode?

Compliance mode is intentionally difficult to bypass. Retention cannot simply be shortened by an administrator. I defaulted the design to Governance mode for testing and require an explicit decision before using Compliance mode.

### Why use remote state for the organization trail?

The trail needs the exact bucket name, KMS key ARN, log prefix, and expected trail ARN prepared by the log-archive stack. Remote state provides a typed contract between separately owned roots. In a larger platform, I could replace this with a dedicated configuration registry or pipeline-generated inputs to reduce state coupling.

### What does `allowed_account_ids` protect against?

It causes the AWS provider to reject credentials for an unexpected account. It is a deployment safety control that helps prevent applying a configuration to the wrong account.

---

## Short portfolio description

Security-first AWS multi-account media-platform reference architecture built with Terraform. The project separates organization governance, GitHub OIDC tooling, delegated GuardDuty/Security Hub operations, centralized CloudTrail audit retention, and dev/staging/prod workloads. It includes an event-driven VOD pipeline and reusable WAF, IAM boundary, Secrets Manager, KMS, and CloudWatch controls. The repository explicitly distinguishes substantive Terraform implementations from application-module scaffolds and documents the remaining validation and deployment gates.

---

## LinkedIn project summary

Designed a Terraform-based AWS multi-account reference architecture for a secure media platform. The solution separates management, CI/CD tooling, security operations, audit retention, and dev/staging/prod workloads; uses GitHub Actions OIDC instead of static AWS keys; centralizes GuardDuty and Security Hub through delegated administration; and delivers organization CloudTrail logs to a KMS-encrypted S3 vault with optional Object Lock. I also implemented an event-driven VOD flow using S3, EventBridge, Step Functions, MediaConvert, SQS, and CloudWatch. The project is documented as a reference architecture prototype, with clear evidence boundaries and a roadmap for full validation and deployment.
