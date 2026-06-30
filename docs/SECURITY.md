# AWS Media Platform Security Standard

**Document version:** 0.1
**Status:** Draft
**Last updated:** YYYY-MM-DD
**Document owner:** Security Lead
**Review frequency:** At least annually and after significant architecture changes

**Related documents:**

* `README.md`
* `docs/MIGRATION_PLAN.md`
* `docs/RUNBOOK.md`
* `docs/VALIDATION.md`
* `infrastructure/`

---

# 1. Purpose

This document defines the security requirements and control standards for the migration and operation of the media platform on Amazon Web Services.

The security design protects:

* User identities and authentication information
* Application and playback APIs
* Media metadata
* Unpublished media
* Published VOD assets
* Live-streaming workflows
* Subtitle and translation files
* Infrastructure configuration
* Encryption keys
* Application secrets
* Operational and security logs
* Administrative access
* Migration and rollback processes

This document describes required controls. Detailed test procedures are maintained in `docs/VALIDATION.md`, while production operational procedures are maintained in `docs/RUNBOOK.md`.

---

# 2. Security Objectives

The security objectives of the platform are to:

1. Prevent unauthorized access to media, metadata, and administrative functions.
2. Ensure that production data is encrypted in transit and at rest.
3. Prevent direct public access to private S3 origin buckets.
4. Apply least-privilege access to human users and AWS services.
5. Protect internet-facing APIs and content-delivery endpoints.
6. Detect suspicious activities and unauthorized configuration changes.
7. Maintain traceable records of infrastructure and administrative actions.
8. Protect secrets, credentials, and encryption keys.
9. Support incident investigation and recovery.
10. Ensure security controls are repeatable through Infrastructure as Code.
11. Separate production and non-production environments.
12. Prevent security controls from being bypassed during migration or rollback.

---

# 3. Scope

## 3.1 In scope

This standard applies to:

* AWS accounts used by the project
* IAM users, roles, groups, and policies
* Amazon Cognito
* Amazon API Gateway
* AWS Lambda
* Amazon DynamoDB
* Amazon S3
* Amazon CloudFront
* CloudFront Origin Access Control
* AWS Elemental MediaLive
* AWS Elemental MediaPackage
* AWS Elemental MediaConvert
* Amazon EventBridge
* AWS Step Functions
* Amazon SQS
* Amazon Transcribe
* Amazon Translate
* AWS KMS
* AWS Secrets Manager
* AWS Systems Manager Parameter Store
* AWS WAF
* AWS Shield
* AWS Firewall Manager
* Amazon CloudWatch
* AWS CloudTrail
* AWS Config
* Amazon GuardDuty
* Route 53
* Terraform or CloudFormation resources
* Deployment pipelines
* Production cutover and rollback activities

## 3.2 Out of scope

Unless separately approved, this document does not define:

* End-user device-hardening standards
* Security requirements for third-party encoder vendors
* Digital-rights-management implementation
* Employee background-check procedures
* Physical data-center controls
* Security controls for unrelated applications
* Formal certification against a particular regulatory standard

---

# 4. Security Principles

The project follows these principles.

## 4.1 Least privilege

Users, applications, and services receive only the permissions required for their approved functions.

## 4.2 Defense in depth

Security controls are applied across:

* Identity
* Application
* API
* Edge
* Storage
* Encryption
* Monitoring
* Configuration
* Recovery

No single security service is treated as sufficient protection.

## 4.3 Deny by default

Access is denied unless explicitly permitted.

## 4.4 Encryption by default

Sensitive information must be encrypted at rest and in transit.

## 4.5 Private origins

S3 media and subtitle origins must remain private. Approved content is distributed through CloudFront.

## 4.6 Temporary access

Human and automated access should use temporary credentials and IAM roles instead of long-term static credentials.

## 4.7 Traceability

Administrative actions and infrastructure changes must be logged, attributable, and reviewable.

## 4.8 Separation of duties

Deployment, security review, approval, and operational responsibilities should not be concentrated in one individual where staffing allows.

## 4.9 Infrastructure as Code

Security-relevant resource configurations should be managed through version-controlled Terraform or CloudFormation.

## 4.10 No security through obscurity

Concealing client-identifying information in project documentation is appropriate, but security must rely on technical controls rather than hidden resource names or architecture details.

---

# 5. Architecture Security Context

The target architecture consists of six functional security areas.

| Flow | Function                | Primary security concerns                                     |
| ---- | ----------------------- | ------------------------------------------------------------- |
| F1   | Authentication and API  | Identity, authorization, API abuse, input validation          |
| F2   | Live streaming          | Encoder trust, service access, input protection, availability |
| F3   | VOD processing          | Upload validation, workflow permissions, queue security       |
| F4   | Subtitle processing     | Confidentiality, integrity, language mapping                  |
| F5   | Content delivery        | Private origins, playback authorization, edge protection      |
| F6   | Security and monitoring | Auditability, detection, compliance, incident response        |

---

# 6. Security Ownership

| Role             | Security responsibilities                                  |
| ---------------- | ---------------------------------------------------------- |
| Security Lead    | Owns this standard, approves exceptions, reviews incidents |
| Cloud Architect  | Ensures architecture satisfies the security design         |
| Cloud Engineer   | Implements AWS security controls                           |
| Application Lead | Secures APIs, Lambda functions, and authentication         |
| Media Engineer   | Secures media ingestion, processing, and origin services   |
| Data Lead        | Protects media and metadata during migration               |
| Operations Lead  | Monitors logs, alarms, queues, and service health          |
| Migration Lead   | Ensures migration actions follow security requirements     |
| Change Manager   | Confirms approvals and change traceability                 |
| Business Owner   | Approves business risks and data-retention requirements    |
| Test Lead        | Verifies security controls through `VALIDATION.md`         |

---

# 7. Required Security Decisions

The following values must be finalized before production approval.

| Decision                  | Proposed approach                                                  | Final value |
| ------------------------- | ------------------------------------------------------------------ | ----------- |
| Primary AWS Region        | Client and regulatory requirements determine selection             | TBD         |
| Account structure         | Separate production and non-production accounts                    | TBD         |
| Central identity system   | IAM Identity Center or approved federation                         | TBD         |
| KMS key model             | Customer-managed keys for sensitive production data                | TBD         |
| Key rotation              | Enable supported automatic rotation                                | TBD         |
| CloudTrail scope          | All Regions, management events, selected data events               | TBD         |
| CloudTrail retention      | Minimum one year proposed                                          | TBD         |
| CloudWatch log retention  | Service-specific periods                                           | TBD         |
| WAF managed rules         | AWS managed baseline rule groups                                   | TBD         |
| WAF rate limits           | Based on tested normal traffic                                     | TBD         |
| Playback authorization    | Signed cookies, signed URLs, or token service                      | TBD         |
| Secrets storage           | Secrets Manager for credentials; Parameter Store for configuration | TBD         |
| GuardDuty scope           | All project accounts and Regions                                   | TBD         |
| Config scope              | All supported production resources                                 | TBD         |
| Security incident channel | Approved incident-management channel                               | TBD         |
| Break-glass access        | Dedicated emergency role with monitoring                           | TBD         |
| Cross-Region backup       | Based on approved RTO and RPO                                      | TBD         |
| Data-retention periods    | Based on business and legal requirements                           | TBD         |

---

# 8. Data Classification

All project information must be classified before production use.

## 8.1 Classification levels

### Public

Information approved for unrestricted public release.

Examples:

* Published marketing content
* Public media manifests where no authorization is required
* Public documentation

### Internal

Information intended for authorized organization personnel.

Examples:

* General architecture documentation
* Non-sensitive operational procedures
* Non-production logs without sensitive content

### Confidential

Information that could cause business, privacy, or security harm if disclosed.

Examples:

* Unpublished media
* User metadata
* Playback history
* Internal media metadata
* Subtitle mappings
* Processing status
* Application logs containing identifiers

### Restricted

Highly sensitive information requiring the strongest access controls.

Examples:

* Credentials
* Private keys
* Authentication tokens
* Encryption-key administration information
* Incident evidence
* Security findings
* Personally identifiable information where present

## 8.2 Data classification matrix

| Data type            | Classification           | Approved storage                       | Encryption         | Public access           |
| -------------------- | ------------------------ | -------------------------------------- | ------------------ | ----------------------- |
| Published media      | Public or Internal       | Private S3 origin                      | Required           | Through CloudFront only |
| Unpublished media    | Confidential             | Private S3                             | Required           | Prohibited              |
| VOD ingest files     | Confidential             | Private S3 ingest bucket               | Required           | Prohibited              |
| Subtitle files       | Internal or Confidential | Private S3 subtitle bucket             | Required           | Through CloudFront only |
| Media metadata       | Confidential             | DynamoDB                               | Required           | Prohibited              |
| User identities      | Confidential             | Cognito                                | Service encryption | Prohibited              |
| API tokens           | Restricted               | Client session or approved token store | Required           | Prohibited              |
| Application secrets  | Restricted               | Secrets Manager                        | Required           | Prohibited              |
| Audit logs           | Confidential             | CloudTrail/S3                          | Required           | Prohibited              |
| Security findings    | Restricted               | GuardDuty/security system              | Required           | Prohibited              |
| Infrastructure state | Restricted               | Encrypted remote state backend         | Required           | Prohibited              |

---

# 9. Identity and Access Management

## 9.1 Human access

Human access must:

* Use named identities.
* Use federation or IAM Identity Center where available.
* Require multifactor authentication for privileged access.
* Use temporary credentials.
* Be assigned through roles rather than shared accounts.
* Be reviewed periodically.
* Be removed promptly when no longer required.
* Be separated between production and non-production access.

Long-term IAM access keys for human administrators are prohibited unless a documented exception is approved.

## 9.2 Role categories

At minimum, define:

| Role                      | Intended access                                      |
| ------------------------- | ---------------------------------------------------- |
| Security administrator    | Security services and security configuration         |
| Cloud deployment role     | Approved Infrastructure as Code deployments          |
| Production operator       | Operational actions without broad administration     |
| Application operator      | API, Lambda, and application monitoring              |
| Media operator            | MediaLive, MediaPackage, and MediaConvert operations |
| Data migration role       | Controlled S3 and DynamoDB migration access          |
| Read-only auditor         | Logs, configurations, and evidence                   |
| Incident responder        | Time-limited investigation and containment           |
| Break-glass administrator | Emergency access only                                |

## 9.3 Break-glass access

The break-glass role must:

* Be used only during approved emergencies.
* Require strong authentication.
* Have no permanently active session.
* Generate immediate security alerts when assumed.
* Be reviewed after each use.
* Have credentials or access mechanisms tested periodically.
* Be excluded from normal deployment activity.

## 9.4 Service roles

Separate service roles must be created for:

* Lambda
* Step Functions
* MediaLive
* MediaConvert
* EventBridge
* API Gateway integrations where required
* Data migration processes
* Deployment pipelines

Service roles must not use broad permissions such as:

```text
Action: "*"
Resource: "*"
```

Unless technically unavoidable and formally approved.

## 9.5 IAM policy requirements

Policies should:

* Restrict resources by ARN.
* Restrict access by environment tags where practical.
* Separate read, write, delete, and administrative permissions.
* Restrict KMS key use.
* Restrict access to production buckets and tables.
* Avoid wildcard principals.
* Avoid unrestricted role assumption.
* Apply conditions such as source account or source ARN where supported.

## 9.6 IAM review

Access reviews should occur:

* Before production cutover
* At least quarterly for privileged access
* After personnel changes
* After security incidents
* After major architecture changes
* When unused permissions are identified

---

# 10. Authentication and Authorization

## 10.1 Cognito

Amazon Cognito should provide approved user authentication.

The Cognito configuration must address:

* Password policy
* Multifactor authentication requirements
* Account recovery
* Token validity periods
* User-registration policy
* Email or phone verification where used
* Failed-login monitoring
* User-pool separation between environments
* Removal or suspension of inactive users

## 10.2 API authorization

API Gateway endpoints must require authorization unless explicitly approved as public.

Authorization may use:

* Cognito user-pool authorizers
* JWT authorizers
* IAM authorization
* Approved custom authorization where required

Administrative APIs must not use the same authorization scope as standard playback APIs.

## 10.3 Authorization model

The application should define authorization levels such as:

| Access level           | Example permission                       |
| ---------------------- | ---------------------------------------- |
| Anonymous              | Access approved public content           |
| Authenticated viewer   | Retrieve authorized playback information |
| Content operator       | Upload and manage media                  |
| Media administrator    | Control processing and publication       |
| Security auditor       | Review security evidence                 |
| Platform administrator | Manage approved platform configuration   |

---

# 11. Network and Edge Security

## 11.1 Public entry points

Approved public entry points are limited to:

* Amazon CloudFront
* Amazon API Gateway
* MediaPackage endpoints where technically required
* To be Approved third-party live-ingest endpoints

S3 buckets, DynamoDB tables, Lambda functions, queues, and administrative services must not be directly exposed as public application endpoints.

## 11.2 TLS

External and internal service-supported connections must use:

* HTTPS
* TLS 1.2 or later
* Valid certificates
* Approved domain names

Plain HTTP should redirect to HTTPS where supported or be disabled.

## 11.3 Route 53

Route 53 changes must:

* Follow the approved change process.
* Be recorded.
* Use health or failover routing where required.
* Be reversible during the rollback period.
* Avoid exposing internal resource details unnecessarily.

## 11.4 Lambda networking

Lambda functions should remain outside a VPC unless private resource access requires VPC connectivity.

When Lambda functions require VPC access:

* Use private subnets.
* Apply restrictive security groups.
* Avoid direct inbound access.
* Use VPC endpoints where appropriate.
* Review NAT Gateway dependency and egress paths.
* Restrict outbound access where feasible.

## 11.5 VPC endpoints

Where appropriate, use VPC endpoints for services such as:

* Amazon S3
* DynamoDB
* Secrets Manager
* Systems Manager
* CloudWatch Logs
* KMS

The requirement depends on the final VPC design.

---

# 12. AWS WAF and DDoS Protection

## 12.1 WAF associations

AWS WAF Web ACLs must be associated with:

* Internet-facing API Gateway stages
* CloudFront distributions

WAF must be treated as a protective control associated with these services, not as an application-processing component between API Gateway, Cognito, or Lambda.

## 12.2 Proposed WAF controls

The initial WAF policy should consider:

* AWS managed common rule set
* Known bad-input protection
* SQL injection protection
* Cross-site scripting protection
* IP reputation rules
* Anonymous-proxy or bot controls where justified
* Request-size restrictions
* Rate-based rules
* Geographic restrictions where approved
* Custom allow or block lists

## 12.3 WAF deployment mode

New rules should initially be evaluated in count mode where practical.

The process should be:

1. Deploy in non-production.
2. Test expected requests.
3. Review false positives.
4. Deploy to production in count mode.
5. Review production traffic.
6. Change to block mode after approval.

## 12.4 DDoS protection

AWS Shield Standard provides baseline protection for supported services.

AWS Shield Advanced should be evaluated based on:

* Business criticality
* DDoS risk
* Financial exposure
* Response requirements
* Required support level

---

# 13. S3 Security and Private Origin Controls

## 13.1 Bucket requirements

All project S3 buckets must:

* Enable Block Public Access.
* Use encryption.
* Use HTTPS-only bucket policies.
* Restrict access to approved roles and services.
* Enable versioning where required.
* Apply lifecycle and retention rules.
* Avoid public ACLs.
* Avoid public bucket policies.
* Use separate buckets or controlled prefixes by purpose.
* Generate access evidence where required.

## 13.2 Bucket separation

Recommended buckets include:

* VOD ingest
* Published VOD origin
* Subtitle origin
* Temporary processing
* Application assets
* Log archive
* Migration staging
* Terraform state

Production and non-production content must not share the same bucket unless a formally approved isolation design exists.

## 13.3 CloudFront Origin Access Control

Private S3 origins must use CloudFront Origin Access Control.

The bucket policy should permit access only from the approved CloudFront distribution and should restrict the source distribution ARN where supported.

Direct requests to private media objects should be denied.

## 13.4 MediaPackage origin

MediaPackage must be configured as a separate CloudFront origin.

S3 Origin Access Control does not apply to MediaPackage endpoints.

MediaPackage origin access and endpoint authorization must follow the selected AWS-supported design.

## 13.5 Object ownership

S3 Object Ownership should be configured to reduce ACL dependency.

Bucket owner enforced mode is preferred where compatible with the workflow.

## 13.6 Object validation

Uploaded objects should be validated for:

* Approved file extension
* Approved MIME type
* Supported codec
* Maximum file size
* Expected naming format
* Required metadata
* Corruption
* Malware-scanning requirements where applicable

Objects that fail validation must not be published.

---

# 14. Content Delivery and Playback Authorization

## 14.1 CloudFront

CloudFront distributions must:

* Redirect HTTP to HTTPS or reject HTTP.
* Use approved TLS policies.
* Use private S3 origins.
* Use WAF.
* Log requests where required.
* Avoid forwarding unnecessary headers, cookies, or query strings.
* Use controlled cache and origin-request policies.
* Restrict administrative paths.
* Apply geographic controls only when approved.

## 14.2 Protected content

Protected content should use one of the following:

* CloudFront signed URLs
* CloudFront signed cookies
* Short-lived authorization tokens generated by the playback API

The final design must document:

* Token validity
* Authorized resource scope
* Key ownership
* Key rotation
* Revocation approach
* User-session handling

## 14.3 Suggested selection

Signed cookies are generally suitable when a viewer requires access to multiple related streaming segments.

Signed URLs may be suitable for:

* Individual files
* Individual download links
* Short-lived access to a specific object

The final decision remains TBD.

## 14.4 Direct-origin access

Users must not bypass CloudFront and retrieve protected content directly from S3.

Testing this requirement is mandatory in `VALIDATION.md`.

---

# 15. Data Encryption and AWS KMS

## 15.1 Encryption at rest

Encryption must be enabled for supported resources, including:

* S3 buckets
* DynamoDB tables
* CloudWatch log groups where required
* SQS queues
* Secrets Manager secrets
* Systems Manager secure parameters
* Terraform state
* Backup data

## 15.2 KMS key model

Customer-managed KMS keys should be considered for:

* Confidential production media
* Restricted logs
* Application secrets
* Sensitive metadata
* Infrastructure state
* Cross-account or cross-Region access requiring controlled key policies

AWS-managed keys may be acceptable for lower-risk workloads where client-managed key control is not required.

## 15.3 Key separation

Consider separate keys for:

* Production media
* Production metadata
* Logs and audit evidence
* Secrets
* Infrastructure state
* Non-production workloads

## 15.4 Key administration

Key administrators must be separate from normal data users where practical.

Key policies must distinguish:

* Key administration
* Encryption and decryption
* Grant creation
* Audit access

## 15.5 Key controls

KMS keys must:

* Have descriptive aliases.
* Be tagged.
* Use controlled key policies.
* Avoid wildcard principals.
* Record use in CloudTrail.
* Use rotation where supported and approved.
* Have deletion protection through an approved process.
* Not be scheduled for deletion during normal cleanup activity.

## 15.6 Key-deletion safeguards

Before scheduling key deletion:

1. Identify all encrypted resources.
2. Confirm approved retention has expired.
3. Confirm recovery is no longer required.
4. Obtain Security Lead approval.
5. Obtain data-owner approval.
6. Record the change.
7. Use the approved waiting period.

---

# 16. Encryption in Transit

All supported communications must use encrypted transport.

This includes:

* Client to CloudFront
* Client to API Gateway
* Encoder to AWS-supported ingest endpoint
* CloudFront to supported origins
* Application to AWS APIs
* Migration tools to S3
* Administrative access to AWS APIs

S3 bucket policies should deny requests that do not use secure transport.

Certificates should be managed through an approved process such as AWS Certificate Manager where supported.

---

# 17. API and Application Security

## 17.1 API Gateway controls

API Gateway should apply:

* Authentication
* Authorization
* Request validation
* Throttling
* Usage controls where required
* WAF protection
* Access logging
* Execution logging where appropriate
* Controlled CORS configuration
* Approved error responses

## 17.2 Input validation

Application requests must validate:

* Required fields
* Data type
* Length
* Allowed values
* File identifiers
* Media identifiers
* Language codes
* Pagination parameters
* User-supplied object keys

User input must not be trusted.

## 17.3 Error handling

External error messages must not expose:

* Stack traces
* IAM role names
* Internal ARNs
* Bucket names unnecessarily
* Database schema details
* Secret values
* Internal network information

Detailed errors should be recorded in protected logs.

## 17.4 Lambda security

Lambda functions must:

* Use separate execution roles.
* Use minimum required permissions.
* Avoid embedding secrets.
* Validate input.
* Set appropriate timeout and memory limits.
* Use supported runtimes.
* Keep dependencies updated.
* Log security-relevant failures.
* Avoid sensitive data in environment variables unless encrypted and justified.
* Restrict reserved concurrency where needed to protect dependencies.

## 17.5 DynamoDB security

DynamoDB tables must:

* Use encryption.
* Restrict access through IAM.
* Enable point-in-time recovery where required.
* Avoid storing unnecessary personal data.
* Use condition expressions where appropriate.
* Prevent unrestricted table scans by untrusted users.
* Record sensitive access where required.

Clients must not receive direct DynamoDB credentials.

---

# 18. Media Workflow Security

## 18.1 Live-stream ingestion

MediaLive inputs must:

* Accept traffic only through the approved input mechanism.
* Restrict source addresses where technically supported.
* Use service roles with minimum permissions.
* Prevent unauthorized channel control.
* Log channel state changes.
* Alert on unexpected input loss.
* Protect endpoint details as confidential operational information.

## 18.2 MediaLive

MediaLive service roles must permit access only to:

* Approved inputs
* Approved MediaPackage destinations
* Required logging destinations
* Required KMS keys
* Required supporting resources

Channel-start and channel-stop permissions should be restricted to approved media operators.

## 18.3 MediaPackage

MediaPackage configuration must:

* Use approved endpoint settings.
* Avoid exposing unnecessary endpoints.
* Restrict administrative actions.
* Record configuration changes.
* Integrate with CloudFront according to the approved delivery design.

## 18.4 VOD ingestion

The VOD ingest bucket must:

* Accept uploads only from approved identities or services.
* Deny anonymous upload.
* Validate uploaded objects before publication.
* Prevent source files from being automatically public.
* Trigger only approved processing workflows.

## 18.5-Step Functions

Step Functions roles must permit only:

* Approved Lambda invocations
* Approved MediaConvert job submission
* Approved SQS operations
* Approved DynamoDB updates
* Approved S3 access

Execution inputs and outputs must not contain secrets.

## 18.6 SQS and DLQ

SQS queues must:

* Use encryption.
* Restrict send and receive permissions.
* Use queue policies with source restrictions.
* Apply approved retention.
* Prevent untrusted services from sending messages.
* Monitor queue depth.
* Monitor dead-letter queue depth.

DLQ messages must be treated as potentially sensitive operational data.

## 18.7 MediaConvert

MediaConvert service roles must:

* Read only from approved input locations.
* Write only to approved output locations.
* Use approved KMS keys.
* Avoid access to unrelated buckets.
* Use approved job templates.

---

# 19. Subtitle and Translation Security

Subtitle workflows must protect:

* Source audio
* Transcription output
* Translation output
* Language metadata
* Subtitle mappings
* Publication status

Controls must include:

* Private S3 storage
* Encryption
* Restricted workflow roles
* Controlled CloudFront delivery
* Validation of subtitle-object references
* Prevention of unauthorized language-file replacement
* Protection against publishing incomplete output

Where subtitles contain personal or confidential dialogue, their classification must match the source media.

---

# 20. Secrets and Configuration Management

## 20.1 Prohibited storage locations

Secrets must not be stored in:

* Source code
* README files
* Terraform files committed to Git
* Plain-text environment files
* CloudFormation templates
* Runbooks
* Chat messages
* Issue trackers
* Container images
* Unencrypted Lambda environment variables

## 20.2 Approved services

Use:

* AWS Secrets Manager for credentials, keys, and rotating secrets
* Systems Manager Parameter Store for approved configuration values
* SecureString parameters for sensitive configuration

## 20.3 Secret access

Secret access must:

* Use IAM roles.
* Be restricted to named resources.
* Be logged.
* Be reviewed.
* Avoid bulk secret retrieval.
* Be removed when the application no longer needs it.

## 20.4 Rotation

Rotation requirements must be defined for:

* Third-party API credentials
* Database credentials where applicable
* Signing keys
* External encoder credentials
* CI/CD integration secrets

---

# 21. Logging, Monitoring, and Detection

## 21.1 CloudTrail

CloudTrail must:

* Be enabled for all approved Regions.
* Record management events.
* Record selected data events for sensitive S3 buckets where required.
* Deliver logs to a protected central location.
* Use encryption.
* Enable log-file validation where required.
* Restrict deletion and modification.
* Integrate with monitoring where necessary.

## 21.2 CloudWatch

CloudWatch should collect:

* API Gateway logs and metrics
* Lambda logs and metrics
* Step Functions status
* SQS and DLQ depth
* MediaConvert job results
* MediaLive health
* MediaPackage health
* CloudFront metrics
* WAF logs or metrics
* Application security events

## 21.3 AWS Config

AWS Config should evaluate controls such as:

* S3 public access
* Encryption status
* CloudTrail status
* IAM policy risk
* Security-group exposure
* Versioning requirements
* Required resource tags
* Approved Region usage

## 21.4 GuardDuty

GuardDuty must be enabled in approved project accounts and Regions.

Findings must:

* Be reviewed.
* Be assigned severity.
* Be routed to an approved response channel.
* Be retained as incident evidence where relevant.
* Trigger immediate review when rated critical or high.

## 21.5 WAF logging

WAF logs should be retained long enough to support:

* Attack analysis
* False-positive review
* Incident investigation
* Rule tuning
* Traffic-baseline analysis

## 21.6 Security alerts

Alerts should cover:

* Root-account use
* Break-glass role use
* Unauthorized API calls
* IAM policy changes
* KMS key-policy changes
* CloudTrail changes
* Config changes
* Public S3 configuration
* Bucket-policy changes
* WAF changes
* Unusual authentication failures
* GuardDuty findings
* DLQ growth
* Repeated media-processing failures
* Unexpected DNS changes

---

# 22. Log Protection and Retention

Logs must:

* Be encrypted.
* Be protected from unauthorized modification.
* Be accessible only to approved operational and security roles.
* Use defined retention periods.
* Avoid unnecessary sensitive data.
* Be available for incident investigation.
* Be deleted only through approved retention procedures.

Proposed retention periods:

| Log type              |                    Proposed retention | Final value |
| --------------------- | ------------------------------------: | ----------- |
| CloudTrail            |                    365 days or longer | TBD         |
| Security findings     |                    365 days or longer | TBD         |
| WAF logs              |                           90–180 days | TBD         |
| Application logs      |                            30–90 days | TBD         |
| Media-processing logs |                               90 days | TBD         |
| Cutover evidence      | Project requirement plus audit period | TBD         |
| Incident records      |              Based on security policy | TBD         |

---

# 23. Infrastructure as Code Security

## 23.1 Repository controls

Infrastructure repositories must use:

* Version control
* Peer review
* Protected branches
* Approved merge process
* Traceable commits
* Restricted write access
* Secret scanning
* Dependency scanning where supported

## 23.2 Terraform state

Terraform state may contain sensitive information.

Remote state must:

* Be encrypted.
* Use restricted IAM access.
* Enable versioning.
* Enable locking.
* Avoid public access.
* Be separated by environment.
* Be backed up according to recovery requirements.

State files must not be committed to Git.

Recommended `.gitignore` entries:

```gitignore
.terraform/
*.tfstate
*.tfstate.*
terraform.tfvars
*.tfplan
crash.log
```

## 23.3 Security scanning

Infrastructure code should be evaluated for:

* Public storage
* Overly broad IAM
* Unencrypted resources
* Exposed security groups
* Missing logging
* Missing versioning
* Hard-coded secrets
* Unapproved Regions
* Missing tags
* Dangerous resource deletion

## 23.4 Production deployment

Production changes must:

1. Be represented in code where possible.
2. Pass formatting and validation.
3. Generate a reviewable plan.
4. Receive peer review.
5. Receive security review for security-sensitive changes.
6. Be applied through an approved role.
7. Be recorded in the change system.
8. Be validated after deployment.

Unreviewed Terraform plans must not be applied to production.

---

# 24. Environment Separation

Production and non-production environments must be separated through:

* Separate AWS accounts where possible
* Separate IAM roles
* Separate S3 buckets
* Separate DynamoDB tables
* Separate Cognito user pools
* Separate API stages or APIs
* Separate CloudFront distributions
* Separate encryption keys where appropriate
* Separate Terraform state
* Separate secrets
* Separate logging and alerting configuration

Production data must not be copied into development or testing unless:

* The business owner approves.
* The Security Lead approves.
* The data is anonymized or minimized.
* Required retention and deletion controls are applied.

---

# 25. Backup and Recovery Security

## 25.1 Required protections

Recovery controls should include:

* S3 versioning
* DynamoDB point-in-time recovery
* Infrastructure code versioning
* Protected configuration backups
* Documented restoration procedures
* DNS rollback records
* Media and metadata reconciliation procedures

## 25.2 Backup access

Backup data must:

* Use encryption.
* Have restricted access.
* Follow retention requirements.
* Be protected against accidental deletion.
* Be tested through restoration exercises.
* Not bypass data-classification requirements.

## 25.3 Cross-Region protection

Cross-Region replication or backup should be implemented only after considering:

* Client privacy requirements
* Data-residency requirements
* Recovery objectives
* Cost
* Key-management design
* Operational complexity

## 25.4 Recovery testing

Recovery tests should confirm:

* S3 object restoration
* DynamoDB point-in-time restoration
* Infrastructure redeployment
* Configuration restoration
* DNS rollback
* Access-control restoration
* Log availability

---

# 26. Migration Security Controls

During migration:

* Source data must not be deleted prematurely.
* Transfer tools must use encrypted connections.
* Migration roles must be temporary and restricted.
* Migration staging buckets must remain private.
* Object counts and checksums must be verified.
* Migration logs must be retained.
* Failed transfers must be recorded.
* Sensitive data must not be copied into personal workstations.
* Data exports must be securely removed when no longer required.
* Production and test data must remain separated.

The Data Lead and Security Lead must approve any migration process that temporarily increases access.

---

# 27. Cutover and Rollback Security

## 27.1 Before cutover

Confirm:

* MFA and role-based access are active.
* CloudTrail is recording.
* GuardDuty and Config are active.
* WAF is attached.
* S3 origins are private.
* KMS keys are active.
* Secrets are stored appropriately.
* Security alarms are functional.
* No unresolved critical security issue exists.

## 27.2 During cutover

Security monitoring must include:

* Authentication failures
* Unauthorized API calls
* WAF blocks
* Public-access changes
* IAM changes
* KMS changes
* CloudTrail changes
* GuardDuty findings
* Unexpected DNS changes
* Direct-origin access attempts

## 27.3 Security rollback triggers

Immediate rollback or isolation should be considered for:

* Public exposure of private media
* Unauthorized access to protected content
* Critical authentication failure
* Loss of audit logging
* Confirmed metadata corruption
* Compromise of credentials
* KMS policy failure
* Critical GuardDuty finding
* Unexpected privileged access
* Inability to contain a security event during cutover

## 27.4 Evidence preservation

During a suspected security incident:

* Do not delete failed messages.
* Do not delete CloudWatch logs.
* Do not remove affected resources before evidence is preserved.
* Record timestamps.
* Preserve CloudTrail records.
* Preserve WAF logs.
* Preserve GuardDuty findings.
* Preserve Step Functions execution histories.
* Preserve client and application errors.

---

# 28. Incident Response

## 28.1 Incident categories

Security incidents may include:

* Unauthorized account access
* Credential exposure
* Public S3 exposure
* Unauthorized media access
* Malicious API activity
* DDoS activity
* Data corruption
* Malicious upload
* Unauthorized configuration change
* Loss of logging
* KMS access failure
* Compromised deployment pipeline

## 28.2 Severity levels

| Severity | Description                            | Example                            |
| -------- | -------------------------------------- | ---------------------------------- |
| Critical | Active major compromise or exposure    | Public confidential media          |
| High     | Serious threat with significant impact | Compromised privileged role        |
| Medium   | Limited impact or contained weakness   | Repeated unauthorized requests     |
| Low      | Minor issue without immediate impact   | Non-critical configuration warning |

## 28.3 Response process

1. Detect and record the event.
2. Assign an incident owner.
3. Classify severity.
4. Preserve evidence.
5. Contain the affected resource or account.
6. Remove malicious access.
7. Recover services.
8. Reconcile affected media and metadata.
9. Notify approved stakeholders.
10. Document root cause.
11. Define corrective actions.
12. Update controls and documentation.

## 28.4 Notification decisions

The Security Lead and Business Owner must determine whether an incident requires:

* Client notification
* Legal review
* Privacy review
* Regulatory notification
* Third-party notification
* Law-enforcement involvement

No external notification claim should be made without approved legal or business review.

---

# 29. Vulnerability and Dependency Management

Application and infrastructure dependencies must be reviewed for:

* Unsupported runtimes
* Known vulnerabilities
* Outdated libraries
* Insecure container images where used
* Vulnerable Terraform providers
* Unsafe application packages
* Unnecessary services

Remediation priority should be based on:

* Exploitability
* Exposure
* Data sensitivity
* Business impact
* Availability of a fix
* Existing compensating controls

Critical internet-facing vulnerabilities should receive the highest priority.

---

# 30. Security Validation Requirements

`VALIDATION.md` must include tests for:

* MFA and privileged-role access
* Unauthorized API rejection
* Expired-token rejection
* WAF rule operation
* API throttling
* Direct S3 access denial
* CloudFront OAC behavior
* Signed URL or cookie expiry
* S3 encryption
* DynamoDB encryption
* Queue encryption
* KMS permission denial
* CloudTrail recording
* Config detection
* GuardDuty alert routing
* WAF log generation
* CloudWatch alarm notification
* IAM least-privilege behavior
* DLQ access restrictions
* Secret retrieval restrictions
* Backup restoration
* Security rollback triggers

A control must not be marked implemented solely because it appears in architecture documentation.

---

# 31. Security Control Matrix

| Control ID | Requirement                            | AWS service or process | Owner            | Status  | Evidence |
| ---------- | -------------------------------------- | ---------------------- | ---------------- | ------- | -------- |
| IAM-01     | MFA for privileged users               | IAM/Identity Center    | Security Lead    | Planned | TBD      |
| IAM-02     | Temporary role-based credentials       | IAM/STS                | Cloud Engineer   | Planned | TBD      |
| IAM-03     | Quarterly privileged-access review     | Governance process     | Security Lead    | Planned | TBD      |
| IAM-04     | Break-glass access monitoring          | IAM/CloudWatch         | Security Lead    | Planned | TBD      |
| API-01     | Authentication on protected APIs       | Cognito/API Gateway    | Application Lead | Planned | TBD      |
| API-02     | Request validation                     | API Gateway/Lambda     | Application Lead | Planned | TBD      |
| API-03     | API throttling                         | API Gateway            | Application Lead | Planned | TBD      |
| WAF-01     | WAF attached to API Gateway            | AWS WAF                | Security Lead    | Planned | TBD      |
| WAF-02     | WAF attached to CloudFront             | AWS WAF                | Security Lead    | Planned | TBD      |
| S3-01      | Block Public Access enabled            | Amazon S3              | Cloud Engineer   | Planned | TBD      |
| S3-02      | Origin access restricted to CloudFront | S3/CloudFront OAC      | Cloud Engineer   | Planned | TBD      |
| S3-03      | Secure transport required              | S3 bucket policy       | Cloud Engineer   | Planned | TBD      |
| S3-04      | Versioning for critical buckets        | Amazon S3              | Data Lead        | Planned | TBD      |
| ENC-01     | Media encrypted at rest                | S3/KMS                 | Cloud Engineer   | Planned | TBD      |
| ENC-02     | Metadata encrypted at rest             | DynamoDB/KMS           | Cloud Engineer   | Planned | TBD      |
| ENC-03     | Queues encrypted                       | SQS/KMS                | Cloud Engineer   | Planned | TBD      |
| ENC-04     | TLS 1.2 or later                       | CloudFront/API Gateway | Cloud Engineer   | Planned | TBD      |
| SEC-01     | Secrets stored outside source code     | Secrets Manager        | Application Lead | Planned | TBD      |
| LOG-01     | CloudTrail enabled                     | CloudTrail             | Security Lead    | Planned | TBD      |
| LOG-02     | Protected central logs                 | S3/KMS                 | Security Lead    | Planned | TBD      |
| LOG-03     | WAF logs retained                      | WAF/CloudWatch/S3      | Operations Lead  | Planned | TBD      |
| DET-01     | GuardDuty enabled                      | GuardDuty              | Security Lead    | Planned | TBD      |
| CFG-01     | Config enabled                         | AWS Config             | Security Lead    | Planned | TBD      |
| CFG-02     | Public S3 detection                    | Config rule            | Security Lead    | Planned | TBD      |
| CDN-01     | Signed access for protected media      | CloudFront             | Application Lead | Open    | TBD      |
| VOD-01     | Upload validation                      | Lambda/Step Functions  | Media Engineer   | Planned | TBD      |
| VOD-02     | DLQ restricted and monitored           | SQS/CloudWatch         | Operations Lead  | Planned | TBD      |
| LIVE-01    | Live input restricted                  | MediaLive              | Media Engineer   | Open    | TBD      |
| IAC-01     | Peer-reviewed production changes       | Git/Terraform          | Cloud Engineer   | Planned | TBD      |
| IAC-02     | Encrypted remote Terraform state       | S3/KMS                 | Cloud Engineer   | Planned | TBD      |
| BAK-01     | DynamoDB PITR enabled                  | DynamoDB               | Data Lead        | Planned | TBD      |
| BAK-02     | Recovery procedures tested             | Operational process    | Operations Lead  | Planned | TBD      |
| IR-01      | Incident response process documented   | Security process       | Security Lead    | Planned | TBD      |

---

# 32. Security Exceptions

A security exception must include:

* Control being excepted
* Business reason
* Technical reason
* Affected resources
* Data classification
* Risk description
* Compensating controls
* Exception owner
* Approval
* Start date
* Expiration date
* Review date
* Remediation plan

Exceptions must not be permanent by default.

## 32.1 Exception record template

| Field                  | Value |
| ---------------------- | ----- |
| Exception ID           |       |
| Control ID             |       |
| Description            |       |
| Business justification |       |
| Risk                   |       |
| Compensating controls  |       |
| Owner                  |       |
| Security approval      |       |
| Business approval      |       |
| Expiration             |       |
| Remediation plan       |       |

---

# 33. Required Security Evidence

The project must retain evidence including:

* IAM role and policy review
* MFA configuration
* Break-glass test
* KMS key-policy review
* S3 Block Public Access status
* CloudFront OAC configuration
* Bucket-policy tests
* WAF associations and rules
* CloudTrail configuration
* Config compliance results
* GuardDuty enablement
* CloudWatch alarm tests
* API authorization tests
* Direct-origin access-denial tests
* Encryption verification
* Secret-storage verification
* Backup restoration results
* Infrastructure review records
* Approved security exceptions
* Incident-response exercise results
* Cutover security sign-off

Evidence must not expose:

* Secret values
* Access tokens
* Private keys
* Full personal information
* Unnecessary client-identifying information

---

# 34. Pre-Production Security Gate

Production deployment must not proceed until:

* [ ] Privileged access requires MFA.
* [ ] Production roles use temporary credentials.
* [ ] IAM policies have been reviewed.
* [ ] S3 Block Public Access is enabled.
* [ ] CloudFront OAC is configured for S3 origins.
* [ ] Direct S3 access is denied.
* [ ] Required encryption is active.
* [ ] KMS policies have been reviewed.
* [ ] API authorization is active.
* [ ] WAF is attached to API Gateway and CloudFront.
* [ ] CloudTrail is active.
* [ ] Config is active.
* [ ] GuardDuty is active.
* [ ] Security alerts are tested.
* [ ] Secrets are not embedded in code.
* [ ] Terraform state is protected.
* [ ] Backup and restoration controls are tested.
* [ ] No unresolved critical security finding exists.
* [ ] Security Lead approval is recorded.

---

# 35. Security Review Schedule

Security reviews must occur:

* Before pilot deployment
* Before production cutover
* At the end of stabilization
* At least annually
* After significant architecture changes
* After critical incidents
* After major IAM changes
* After changes to content-authorization design
* Before on-premises decommissioning

---

# 36. Final Security Acceptance

The environment is security-ready when:

* Required controls are implemented.
* Required security tests pass.
* No unresolved critical finding exists.
* High-risk findings have approved remediation or exception plans.
* Monitoring and logging are operational.
* Security incident procedures are available.
* Recovery controls have been tested.
* Required evidence has been retained.
* The Security Lead has approved production use.

---

# 37. Approval

| Role             | Name | Decision | Date | Signature or record |
| ---------------- | ---- | -------- | ---- | ------------------- |
| Security Lead    |      |          |      |                     |
| Cloud Architect  |      |          |      |                     |
| Cloud Engineer   |      |          |      |                     |
| Application Lead |      |          |      |                     |
| Media Engineer   |      |          |      |                     |
| Operations Lead  |      |          |      |                     |
| Migration Lead   |      |          |      |                     |
| Business Owner   |      |          |      |                     |
