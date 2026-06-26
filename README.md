# Project Title: Media Company On-premise architecture Migration to AWS (Privacy concerned from my client, therefore conceal.)

## 1. Executive Summary

**This project presents the proposed migration of an on-premises media streaming platform to Amazon Web Services (AWS). To protect client confidentiality, identifying information and sensitive details about the existing environment have been omitted.**

*The target architecture supports both live-streaming and Video on Demand (VOD) workloads. Media content is ingested from external video sources and on-premises live encoders before being processed, stored, and distributed through a combination of managed and serverless AWS services.*

***The solution uses services including AWS Elemental MediaLive, AWS Elemental MediaPackage, AWS Elemental MediaConvert, Amazon S3, AWS Lambda, and Amazon CloudFront to create a scalable end-to-end media workflow. By replacing infrastructure-dependent components with managed AWS services, the architecture reduces operational overhead and allows capacity to scale according to viewer demand.***

*The platform also integrates Amazon Transcribe and Amazon Translate to automate subtitle transcription and multilingual translation. Translated subtitle files can then be delivered according to the viewer's selected language or regional requirements.*

**The primary objectives of the migration are to:**

1. Improve platform availability and resilience.
2. Support unpredictable and rapidly changing audience demand.
3. Reduce infrastructure management and manual operational tasks.
4. Optimize storage, processing, and content-delivery costs.
5. Strengthen security, monitoring, auditing, and governance.
6. Provide globally distributed, low-latency media delivery.

**The resulting architecture provides a secure, highly available, and globally scalable streaming platform while giving the organization greater flexibility to expand its digital media services.**

## 2. Business Criteria & Service Mapping
### 2.1 High Availability and Resilience

**Business requirement:**
The streaming platform must provide at least 99.9% service availability and minimize interruptions to live broadcasts and on-demand content delivery.

**AWS service mapping:**

* **AWS Elemental MediaLive – Standard Class:**
  Live channels use two independent processing pipelines. This provides pipeline redundancy and reduces the risk of a single encoder or infrastructure failure interrupting a broadcast.

* **AWS Elemental MediaPackage:**
  MediaPackage receives encoded streams from MediaLive and prepares them for delivery in multiple streaming formats. It provides a managed origin and helps maintain reliable stream packaging and distribution.

* **Amazon S3:**
  VOD source files, processed media assets, subtitles, and supporting content are stored in Amazon S3, which provides durable and scalable object storage.

* **Amazon CloudFront:**
  CloudFront distributes live and VOD content through globally distributed edge locations. Cached content can be served closer to viewers, improving performance and reducing the load placed on origin services.

* **Amazon Route 53:**
  Route 53 provides highly available DNS resolution and can support health-based or failover routing where required.

Together, these services remove several single points of failure from the existing environment and provide a more resilient content-processing and delivery path.

### 2.2 Scalability and Unpredictable Audience Demand

**Business requirement:**
The expected number of online viewers has not yet been clearly established. The platform must therefore accommodate both low-traffic periods and sudden increases in demand without requiring significant manual capacity planning.

**AWS service mapping:**

* **Amazon CloudFront:**
  CloudFront scales content delivery across AWS edge locations and absorbs a significant portion of viewer traffic before requests reach the origin.

* **Amazon API Gateway:**
  API Gateway provides a managed and scalable entry point for application APIs, such as user-profile, content-catalogue, subtitle-selection, and playback-authorization requests.

* **AWS Lambda:**
  Lambda automatically scales in response to incoming events and API requests. It can support media-processing orchestration, metadata updates, subtitle workflows, and application backend functions without continuously running servers.

* **Amazon DynamoDB – On-Demand Capacity Mode:**
  DynamoDB can store media metadata, viewer preferences, subtitle mappings, and processing status information. On-demand capacity is suitable during the early stages of the platform because traffic patterns are uncertain, and the database can automatically scale with application demand.

This approach allows the organization to launch the platform without committing to large amounts of pre-provisioned infrastructure.

### 2.3 Cost Optimization

**Business requirement:**
The organization wants to minimize unnecessary cloud expenditure because the initial audience size and long-term content-consumption patterns remain uncertain.

**AWS service mapping:**

* **Amazon DynamoDB On-Demand Capacity:**
  The business pays for the database requests consumed rather than maintaining provisioned read and write capacity during periods of low demand.

* **Amazon S3 Lifecycle Policies:**
  Lifecycle rules can automatically transition older or less frequently accessed media assets into lower-cost storage classes. Retention and deletion rules can also be applied to temporarily ingest files, intermediate processing outputs, and expired content.

* **AWS Lambda and Amazon API Gateway:**
  Request-based pricing avoids the cost of running application servers continuously when workloads are intermittent or traffic is low.

* **Amazon CloudFront Caching:**
  Frequently requested media segments and supporting files are cached at edge locations, reducing repeated requests to the origin and lowering origin-processing and data-transfer requirements.

* **AWS Elemental MediaConvert:**
  MediaConvert provides managed, job-based video transcoding. The organization pays for completed processing work without operating a permanent transcoding cluster.

* **AWS Cost Explorer and AWS Budgets:**
  Cost Explorer can be used to analyze expenditure by service, account, or tag, while AWS Budgets can notify stakeholders when actual or forecast spending exceeds an agreed threshold.

These controls establish a consumption-based cost model while providing mechanisms to monitor and govern expenditure as the platform grows.

### 2.4 Operational Excellence and Automation

**Business requirement:**
The platform should reduce manual administration so that the engineering team can focus on security, governance, service improvement, and incident response.

**AWS service mapping:**

* **Managed Media Services:**
  AWS Elemental MediaLive, MediaPackage, and MediaConvert reduce the need to maintain operating systems, encoding servers, codec packages, and custom scaling mechanisms.

* **Event-Driven Processing:**
  Amazon S3 events, Amazon EventBridge, AWS Step Functions, and AWS Lambda can automate media-ingestion, transcoding, transcription, translation, metadata-update, and notification workflows.

* **Amazon CloudWatch:**
  CloudWatch collects service metrics, application logs, and operational events. Alarms can notify the engineering team when processing jobs fail, API errors increase, or service performance exceeds defined thresholds.

* **AWS CloudTrail:**
  CloudTrail records account activity and AWS API operations, supporting security investigation, operational troubleshooting, and governance reviews.

* **Infrastructure as Code:**
  Terraform or AWS CloudFormation can be used to create repeatable environments, reduce configuration drift, and ensure that infrastructure changes are version-controlled and reviewable.

Automation and centralized observability reduce operational effort while improving the consistency and traceability of platform changes.

### 2.5 Security and Governance

**Business requirement:**
The migrated environment must protect media assets, application interfaces, viewer information, and administrative operations.

**AWS service mapping:**

* **AWS Identity and Access Management:**
  IAM roles and policies enforce least-privilege access for administrators, applications, and AWS services.

* **AWS Key Management Service:**
  AWS KMS manages encryption keys used to protect supported data stores and application resources.

* **AWS WAF:**
  WAF protects CloudFront and API Gateway endpoints against common application-layer threats, such as SQL injection, cross-site scripting, malicious bots, and abnormal request patterns.

* **AWS Shield:**
  AWS Shield provides protection against distributed denial-of-service attacks affecting supported AWS edge and application services.

* **Amazon S3 Block Public Access and CloudFront Origin Access Control:**
  Media buckets remain private, while authorized content is delivered through CloudFront rather than being exposed directly from Amazon S3.

* **AWS CloudTrail and AWS Config:**
  CloudTrail records account activity, while AWS Config evaluates resource configurations and supports the detection of unauthorized or non-compliant changes.

These services establish layered security controls across identity, data protection, application access, network entry points, monitoring, and governance.

## 3. Architecture Overview
* **Current State (On-Premises):** *(Insert image link: `![On-Prem Architecture](./architecture/Receive_Note.png)`)*
  [Briefly describe the bottlenecks of the legacy setup.]
* **Target State (Cloud):** *(Insert image link: `![Target Architecture](./architecture/AWS_final_version_architecture.png)`)*
  [Briefly describe the flow of the new architecture, highlighting network boundaries and subnets.]

## 4. Migration Strategy
### 4.1 Migration Approach

The migration uses a combination of **re-platforming** and **refactoring** rather than reproducing the existing on-premises environment directly in AWS.

Core media capabilities are re-platformed onto managed AWS services, while application workflows are refactored into serverless and event-driven components. This approach reduces infrastructure-management overhead, improves scalability, and allows the platform to respond more effectively to unpredictable viewer demand.

The principal workload transitions are:

* **Live-stream processing:** Re-platformed from on-premises encoding infrastructure to AWS Elemental MediaLive and AWS Elemental MediaPackage.
* **VOD processing:** Refactored into an event-driven workflow using Amazon S3, Amazon EventBridge, AWS Step Functions, AWS Lambda, and AWS Elemental MediaConvert.
* **Media storage:** Migrated to private Amazon S3 buckets with lifecycle policies for long-term cost optimization.
* **Metadata and processing status:** Re-platformed to Amazon DynamoDB using on-demand capacity during the initial operating period.
* **Application APIs:** Refactored to use Amazon API Gateway and AWS Lambda where appropriate.
* **Subtitle generation:** Automated using Amazon Transcribe, Amazon Translate, AWS Lambda, and Amazon S3.
* **Content delivery:** Migrated to Amazon CloudFront to provide globally distributed, low-latency delivery for live streams, VOD assets, and subtitle files.

### 4.2 Migration Phases

#### Phase 1 – Discovery and Assessment

The existing environment is assessed to identify:

* Application and infrastructure dependencies.
* Live-stream and VOD processing workflows.
* Media formats, codecs, resolutions, and storage requirements.
* Network bandwidth and connectivity requirements.
* Metadata schemas and database dependencies.
* Security, privacy, retention, and compliance requirements.
* Recovery objectives and acceptable service-interruption periods.

The results are used to prioritize workloads, estimate migration effort, identify technical risks, and establish measurable success criteria.

#### Phase 2 – AWS Foundation and Landing Zone

Before production workloads are migrated, the AWS environment is prepared with:

* Separate accounts or environments for development, testing, staging, and production.
* Centralized identity and access controls.
* Logging, auditing, monitoring, and cost-management services.
* Encryption keys and security policies.
* Private S3 buckets and CloudFront Origin Access Control.
* Infrastructure as Code templates for repeatable deployment.
* Resource tagging standards and budget notifications.

This foundation ensures that security, governance, and operational controls are established before media assets or production traffic are introduced.

#### Phase 3 – Pilot Migration

A limited pilot workload is migrated first. The pilot should include representative media content and a non-critical live or VOD workflow.

The pilot validates:

* Media ingestion and transcoding.
* Playback compatibility across supported devices.
* Subtitle transcription and translation.
* API and metadata processing.
* CloudFront caching and origin access.
* Monitoring, alerting, and operational procedures.
* Performance, security, and estimated operating costs.

Issues identified during the pilot are resolved before the production migration begins.

#### Phase 4 – Media and Metadata Migration

Existing VOD assets are transferred to Amazon S3 in controlled batches. File checksums, object counts, metadata, and playback results are validated after each transfer.

Where necessary, AWS DataSync or multipart upload processes may be used to improve the reliability of large data transfers. Frequently accessed content should be migrated first, while archival content may be transferred later or placed directly into an appropriate lower-cost storage class.

Application metadata is migrated to DynamoDB or another selected target database using tested transformation and validation procedures.

#### Phase 5 – Application and Workflow Migration

Application services are migrated incrementally to reduce operational risk. Event-driven workflows are introduced for:

* Media ingestion.
* Transcoding.
* Thumbnail generation.
* Transcription and translation.
* Metadata updates.
* Processing-status tracking.
* Failure notifications.
* Content-publication approval.

The on-premises and AWS environments may operate in parallel during this phase to support testing and reduce the effect of individual migration failures.

#### Phase 6 – Production Cutover

Before cutover, the project team should:

1. Complete final synchronization of media assets and metadata.
2. Confirm that monitoring dashboards and alarms are operational.
3. Validate live-stream and VOD playback from multiple locations and devices.
4. Confirm that security, backup, recovery, and operational runbooks have been tested.
5. Reduce DNS time-to-live values where DNS changes are required.
6. Establish a temporary change freeze for the affected production systems.
7. Obtain formal approval from technical and business stakeholders.

Production traffic is then redirected gradually to the AWS environment. Key service indicators—including playback failures, API errors, latency, dropped frames, processing failures, and CloudFront error rates—are monitored closely throughout the cutover period.

#### Phase 7 – Stabilization and Optimization

Following a successful cutover, the AWS environment enters a stabilization period. During this period, the team reviews:

* Service availability and application performance.
* Media-processing success and failure rates.
* CloudFront cache effectiveness.
* Storage-class usage and lifecycle rules.
* DynamoDB capacity and access patterns.
* Security findings and configuration changes.
* Actual expenditure compared with the projected budget.

The on-premises environment should only be decommissioned after the AWS platform has operated successfully for an agreed validation period and all rollback requirements have expired.

### 4.3 Validation and Success Criteria

The migration is considered successful when:

* Live and VOD content can be delivered through the AWS platform without unacceptable interruption.
* Supported media formats and subtitle languages function correctly.
* Migrated files and metadata pass integrity checks.
* Application performance meets agreed latency and availability targets.
* Security and access-control tests produce no unresolved critical findings.
* Monitoring, alerting, backup, and recovery procedures operate as expected.
* Operating costs remain within the approved budget thresholds.

### 4.4 Rollback Strategy

The existing on-premises platform remains available during the agreed rollback window.

Rollback may be initiated if the AWS environment experiences critical playback failures, unacceptable performance degradation, data-integrity problems, security issues, or repeated processing failures that cannot be corrected within the approved cutover period.

The rollback process includes:

* Redirecting traffic to the existing on-premises endpoints.
* Restoring the previous DNS or routing configuration.
* Stopping new media ingestion into the affected AWS workflow.
* Reconciling media assets and metadata created during the cutover.
* Recording the failure cause and corrective actions before another migration attempt.

Detailed cutover and rollback instructions should be maintained in `/docs/RUNBOOK.md`.

---

## 5. Security Deployment & Governance
### 5.1 Security Design Principles

The target environment follows the principles of:

* Least-privilege access.
* Defense in depth.
* Encryption by default.
* Private origin access.
* Centralized logging and monitoring.
* Separation of production and non-production environments.
* Automated configuration and compliance checks.
* Traceable and reviewable infrastructure changes.

Security controls should be defined through Infrastructure as Code wherever possible so that configurations can be consistently deployed, reviewed, and reproduced.

### 5.2 Identity and Access Management

AWS Identity and Access Management roles are used for application components, automated workflows, administrators, and deployment pipelines.

The identity design includes:

* Least-privilege IAM policies.
* Role-based access rather than long-term shared credentials.
* Multifactor authentication for privileged users.
* Separation of administrative, operational, and read-only responsibilities.
* Temporary credentials for services and automation processes.
* Regular review of unused permissions, roles, and access keys.
* Restricted access to production resources and encryption keys.

Service roles for MediaLive, MediaConvert, Lambda, Step Functions, and other AWS services should only permit access to the specific resources required by each workflow.

### 5.3 Network and Edge Security

The architecture primarily uses managed AWS services and does not expose media-storage buckets directly to the public internet.

Public entry points are limited to approved services such as:

* Amazon CloudFront for media distribution.
* Amazon API Gateway for application API requests.
* AWS Elemental MediaPackage endpoints where required.

AWS WAF protects CloudFront and API Gateway against common application-layer attacks, malicious requests, bots, and abnormal request patterns. AWS Shield provides additional protection against distributed denial-of-service attacks affecting supported endpoints.

Amazon S3 Block Public Access remains enabled, and CloudFront Origin Access Control restricts access so that media objects can be retrieved through the approved CloudFront distribution rather than directly from the S3 origin.

Where Lambda functions require access to private resources, they are placed in private subnets with restrictive security groups. VPC endpoints should be used where appropriate to reduce reliance on public network paths.

### 5.4 Data Protection

Data is protected throughout its lifecycle.

Controls include:

* Encryption at rest using AWS Key Management Service-managed keys where supported.
* HTTPS and TLS 1.2 or later for data in transit.
* Private S3 buckets with blocked public access.
* S3 versioning for critical media, configuration, and subtitle assets.
* Lifecycle and retention policies based on business and regulatory requirements.
* Restricted access to KMS keys through key policies and IAM permissions.
* Encryption of application secrets and sensitive configuration values.
* Secure deletion or expiration of temporary ingest and processing files.

Production data should not be copied into development or testing environments unless it has been appropriately anonymized or approved.

### 5.5 Application and API Protection

Application APIs are exposed through Amazon API Gateway and protected using appropriate authorization, throttling, request validation, and AWS WAF rules.

Depending on the application requirements, playback authorization may use signed CloudFront URLs, signed cookies, or short-lived access tokens to reduce unauthorized distribution of protected content.

Sensitive information—such as API credentials, third-party integration keys, and database connection values—should be stored in AWS Secrets Manager or AWS Systems Manager Parameter Store rather than embedded in source code or Infrastructure as Code templates.

### 5.6 Logging, Monitoring, and Detection

Security and operational events are centrally recorded and monitored.

The target controls include:

* AWS CloudTrail for AWS account activity and API auditing.
* Amazon CloudWatch for application logs, service metrics, dashboards, and alarms.
* AWS Config for configuration tracking and compliance evaluation.
* AWS WAF logs for analysis of blocked and suspicious requests.
* Amazon S3 access logs or CloudTrail data events for sensitive bucket operations where required.
* Alerts for unauthorized access attempts, policy changes, processing failures, elevated API errors, and abnormal traffic patterns.

Logs should be protected against unauthorized modification and retained according to operational, legal, and compliance requirements.

### 5.7 Governance and Change Management

Infrastructure changes are managed through version-controlled Terraform or AWS CloudFormation templates.

The governance process should require:

* Peer review of infrastructure changes.
* Testing in a non-production environment.
* Approval before production deployment.
* Resource tagging for ownership, environment, project, and cost allocation.
* AWS Budgets and cost alerts.
* Periodic IAM and security-policy reviews.
* Automated configuration checks using AWS Config.
* Documentation of exceptions and accepted risks.
* Regular review of AWS service limits and quotas.

Where multiple AWS accounts are used, AWS Organizations and service control policies can establish organization-wide restrictions and prevent prohibited actions.

### 5.8 Backup, Recovery, and Incident Response

Backup and recovery controls are established for media assets, metadata, configuration, and infrastructure definitions.

The recovery design includes:

* S3 versioning and appropriate replication or backup controls for critical assets.
* DynamoDB point-in-time recovery for important metadata tables.
* Version-controlled Infrastructure as Code templates.
* Documented restoration procedures.
* Tested incident-response and rollback runbooks.
* Defined recovery time and recovery point objectives.
* Periodic recovery exercises.

Security and operational incidents should be documented, investigated, and reviewed to identify corrective actions and improvements to the platform.


## 6. Repository Navigation
* `/docs/MIGRATION_PLAN.md` - Full phase-by-phase migration journey.
* `/docs/RUNBOOK.md` - Cutover strategy and rollback procedures.
* `/infrastructure/` - Infrastructure as Code (IaC) templates used for deployment.

## 7. How to Deploy (Optional but Recommended)
1. Clone the repository.
2. Initialize the environment using `terraform init` or deploy the CloudFormation stack.
3. [Any other required commands...]