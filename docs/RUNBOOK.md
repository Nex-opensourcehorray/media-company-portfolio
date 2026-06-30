# AWS Media Platform Production Runbook

**Document version:** 0.1
**Status:** Draft
**Last updated:** YYYY-MM-DD
**Document owner:** Migration Lead
**Related documents:**

* `README.md`
* `docs/MIGRATION_PLAN.md`
* `docs/SECURITY.md`
* `docs/VALIDATION.md`
* `infrastructure/`

---

## 1. Purpose

This runbook defines the operational procedures for deploying, validating, cutting over, monitoring, and, where necessary, rolling back the migration of the media platform from the existing on-premises environment to AWS.

The runbook covers the following target architecture flows:

| Flow | Function                             |
| ---- | ------------------------------------ |
| F1   | Authentication and application API   |
| F2   | Live-stream processing               |
| F3   | VOD processing                       |
| F4   | Subtitle processing                  |
| F5   | Content delivery                     |
| F6   | Security, monitoring, and governance |

This document is intended for production operations. Every production action must be recorded in the approved change record.

---

## 2. Required Decisions and Environment Values

The following values must be completed before this runbook is approved for production use.

### 2.1 Environment information

| Item                            | Value  | Status   |
| ------------------------------- | ------ | -------- |
| AWS account ID                  | TBD    | Open     |
| Primary AWS Region              | TBD    | Open     |
| AWS CLI production profile      | TBD    | Open     |
| Production environment name     | `prod` | Proposed |
| Route 53 hosted zone ID         | TBD    | Open     |
| Production domain               | TBD    | Open     |
| API Gateway production endpoint | TBD    | Open     |
| CloudFront distribution ID      | TBD    | Open     |
| CloudFront production domain    | TBD    | Open     |
| MediaPackage live endpoint      | TBD    | Open     |
| VOD ingest bucket               | TBD    | Open     |
| Published VOD bucket            | TBD    | Open     |
| Subtitle bucket                 | TBD    | Open     |
| DynamoDB metadata table         | TBD    | Open     |
| VOD processing queue            | TBD    | Open     |
| VOD dead-letter queue           | TBD    | Open     |
| Step Functions state machine    | TBD    | Open     |
| EventBridge ingestion rule      | TBD    | Open     |
| MediaLive channel ID            | TBD    | Open     |
| CloudWatch dashboard            | TBD    | Open     |
| CloudWatch alarm topic          | TBD    | Open     |
| Log archive location            | TBD    | Open     |

### 2.2 Cutover information

| Item                              | Value                                  | Status   |
| --------------------------------- | -------------------------------------- | -------- |
| Cutover date                      | TBD                                    | Open     |
| Cutover start time                | TBD                                    | Open     |
| Approved maintenance window       | TBD                                    | Open     |
| Change-freeze start time          | TBD                                    | Open     |
| DNS TTL before cutover            | 60–300 seconds                         | Proposed |
| Traffic migration strategy        | Weighted routing or client groups      | Open     |
| Rollback window                   | TBD                                    | Open     |
| Stabilization period              | 14 days                                | Proposed |
| Maximum cutover incident duration | 30 minutes                             | Proposed |
| Final synchronization method      | DataSync, S3 sync, or approved process | Open     |

### 2.3 Proposed operational thresholds

These values must be confirmed in `VALIDATION.md` and approved before cutover.

| Metric                      |            Warning threshold |                   Rollback threshold |
| --------------------------- | ---------------------------: | -----------------------------------: |
| API Gateway 5xx error rate  |   More than 1% for 5 minutes |          More than 2% for 10 minutes |
| CloudFront 5xx error rate   |   More than 1% for 5 minutes |          More than 2% for 10 minutes |
| Playback failure rate       |   More than 2% for 5 minutes |          More than 3% for 10 minutes |
| Authentication failure rate |      More than 1.5× baseline | More than 2× baseline for 10 minutes |
| API p95 latency             |             More than 800 ms |    More than 1,500 ms for 10 minutes |
| Lambda errors               |                 More than 1% |          More than 3% for 10 minutes |
| Lambda throttles            |     Any sustained throttling |   Sustained for more than 10 minutes |
| MediaConvert failures       | More than 2 consecutive jobs |                Five consecutive jobs |
| Step Functions failures     |    More than 2 in 10 minutes |                   Five in 10 minutes |
| VOD DLQ depth               |         One or more messages |      Increasing depth for 10 minutes |
| MediaLive input loss        |         More than 10 seconds |                 More than 60 seconds |
| Dropped-frame rate          |      Above approved baseline |      Sustained unacceptable playback |
| Metadata mismatch           |   Any warning-level mismatch |          Confirmed integrity failure |
| Unauthorized content access |               Not applicable |      Immediate rollback or isolation |
| Critical GuardDuty finding  |               Not applicable |          Immediate security decision |

---

## 3. Roles and Responsibilities

| Role                | Primary responsibilities                                       |
| ------------------- | -------------------------------------------------------------- |
| Migration Lead      | Coordinates the cutover and makes operational decisions        |
| Change Manager      | Maintains the change record and verifies approvals             |
| Cloud Engineer      | Deploys and verifies AWS infrastructure                        |
| Application Lead    | Verifies API Gateway, Lambda, Cognito, and DynamoDB            |
| Media Engineer      | Verifies MediaLive, MediaPackage, MediaConvert, and playback   |
| Data Lead           | Performs media and metadata synchronization and reconciliation |
| Security Lead       | Verifies security controls and evaluates security incidents    |
| Operations Lead     | Monitors dashboards, alarms, logs, and service health          |
| Test Lead           | Executes validation tests and records evidence                 |
| Business Owner      | Approves production service acceptance                         |
| Communications Lead | Sends status and incident communications                       |

### 3.1 Decision authority

| Decision                            | Authorized role                   |
| ----------------------------------- | --------------------------------- |
| Begin cutover                       | Migration Lead and Change Manager |
| Increase AWS traffic                | Migration Lead                    |
| Pause traffic progression           | Operations Lead or Migration Lead |
| Initiate technical rollback         | Migration Lead                    |
| Immediate security isolation        | Security Lead                     |
| Accept residual business risk       | Business Owner                    |
| Declare cutover complete            | Migration Lead and Business Owner |
| Approve on-premises decommissioning | Business Owner and Security Lead  |

### 3.2 Contact and escalation matrix

| Role             | Name | Contact | Backup |
| ---------------- | ---- | ------- | ------ |
| Migration Lead   | TBD  | TBD     | TBD    |
| Cloud Engineer   | TBD  | TBD     | TBD    |
| Media Engineer   | TBD  | TBD     | TBD    |
| Application Lead | TBD  | TBD     | TBD    |
| Security Lead    | TBD  | TBD     | TBD    |
| Operations Lead  | TBD  | TBD     | TBD    |
| Business Owner   | TBD  | TBD     | TBD    |

---

## 4. Security and Access Requirements

Before executing this runbook:

* All privileged operators must use named accounts.
* Multifactor authentication must be enabled.
* Temporary role-based credentials must be used.
* Long-term shared credentials must not be used.
* Access must be limited to the approved production roles.
* Credentials, secrets, tokens, and private keys must not be recorded in this document.
* Sensitive values must be retrieved from AWS Secrets Manager or Systems Manager Parameter Store.
* Production actions must be recorded in CloudTrail.
* The operator must verify the active AWS account and Region before running commands.

### 4.1 Confirm AWS identity

```bash
aws sts get-caller-identity \
  --profile <PRODUCTION_PROFILE>
```

Expected result:

* The returned account ID matches the approved production AWS account.
* The returned ARN identifies the approved deployment or operations role.

### 4.2 Confirm active Region

```bash
aws configure get region \
  --profile <PRODUCTION_PROFILE>
```

Expected result:

```text
<APPROVED_PRIMARY_REGION>
```

**Hard stop:** Do not continue when the account, role, or Region is incorrect.

---

## 5. Required Tools

The following tools must be installed and tested:

* AWS CLI
* Terraform or the approved CloudFormation deployment tooling
* Git
* `curl`
* `nslookup` or `dig`
* Media playback test clients
* Checksum utility
* Access to AWS Management Console
* Access to monitoring and communication systems

### 5.1 Verify tools

```bash
aws --version
terraform version
git --version
curl --version
```

The installed versions must meet the project’s approved minimum requirements.

---

## 6. Change Management Procedure

### 6.1 Required approvals

Before cutover, confirm approval from:

* Migration Lead
* Change Manager
* Security Lead
* Operations Lead
* Application Lead
* Media Engineer
* Business Owner

### 6.2 Change record

Record:

| Field                 | Value                                       |
| --------------------- | ------------------------------------------- |
| Change ID             | TBD                                         |
| Planned start         | TBD                                         |
| Planned end           | TBD                                         |
| Systems affected      | On-premises platform and AWS media platform |
| Business impact       | TBD                                         |
| Rollback owner        | TBD                                         |
| Communication channel | TBD                                         |
| Final approval time   | TBD                                         |

### 6.3 Change freeze

During the change freeze:

* Do not deploy unrelated application changes.
* Do not modify IAM policies unless required to resolve the cutover.
* Do not change S3 lifecycle policies.
* Do not change DynamoDB schemas or key structures.
* Do not change encoding profiles.
* Do not modify WAF rules without Security Lead approval.
* Do not upload non-essential production media.
* Do not change DNS outside the approved procedure.

---

# 7. Pre-Cutover Preparation

These activities should normally be completed between seven days and twenty-four hours before cutover.

## 7.1 Infrastructure readiness

Verify that the following resources exist and are healthy:

### F1 — Authentication and API

* Route 53 configuration
* API Gateway production stage
* Cognito user pool
* Lambda functions
* DynamoDB metadata table
* API Gateway WAF Web ACL

### F2 — Live streaming

* MediaLive Standard channel
* Both MediaLive pipelines
* MediaPackage live origin
* Live encoder input
* Live monitoring alarms

### F3 — VOD processing

* Private S3 ingest bucket
* EventBridge ingestion rule
* Step Functions state machine
* MediaConvert queue and templates
* SQS processing queue
* Dead-letter queue
* Private published VOD bucket

### F4 — Subtitle processing

* Transcribe workflow
* Translate workflow
* Private subtitle bucket
* Subtitle metadata mapping
* Subtitle delivery path

### F5 — Content delivery

* CloudFront distribution
* S3 origins
* MediaPackage origin
* Origin Access Control for private S3 origins
* Cache policies
* Origin request policies
* Signed URL or signed-cookie configuration where required

### F6 — Security and monitoring

* CloudTrail
* CloudWatch dashboards
* CloudWatch alarms
* AWS Config
* GuardDuty
* AWS WAF
* AWS KMS
* Firewall Manager where applicable
* Central log storage

## 7.2 Infrastructure as Code checks

From the infrastructure directory:

```bash
cd infrastructure
terraform fmt -check -recursive
terraform init
terraform validate
```

Expected result:

* Formatting check passes.
* Initialization completes successfully.
* Validation reports no errors.

Create and save the production plan:

```bash
terraform plan \
  -var-file="production.tfvars" \
  -out="production-cutover.tfplan"
```

The Cloud Engineer and a second reviewer must inspect the plan.

Confirm that the plan does not unexpectedly:

* Delete production resources
* Replace KMS keys
* Remove S3 buckets
* Remove DynamoDB tables
* Disable logging
* Remove WAF protection
* Open public S3 access
* Change IAM permissions beyond the approved scope
* Replace CloudFront distributions unexpectedly

Record the plan review:

| Reviewer       | Time | Result | Evidence |
| -------------- | ---- | ------ | -------- |
| Cloud Engineer |      |        |          |
| Peer reviewer  |      |        |          |
| Security Lead  |      |        |          |

## 7.3 Security readiness

Confirm:

* S3 Block Public Access is enabled.
* S3 origin buckets are not directly public.
* CloudFront Origin Access Control is active for S3 origins.
* IAM roles follow the least privilege.
* Privileged users use MFA.
* KMS encryption is enabled where required.
* CloudTrail is recording events.
* Config is evaluating resources.
* GuardDuty is enabled.
* WAF logging is enabled.
* CloudWatch logs have approved retention.
* Secrets are not embedded in source code.
* No unresolved critical security finding exists.

## 7.4 Backup and recovery readiness

Confirm:

* S3 versioning is enabled for critical buckets.
* DynamoDB point-in-time recovery is enabled where required.
* Infrastructure code is committed and tagged.
* Existing on-premises backups are current.
* Previous DNS configuration is recorded.
* Current application configuration is exported.
* Rollback instructions have been reviewed.
* Required restoration procedures have been tested.

## 7.5 Monitoring readiness

Confirm dashboards display:

* API Gateway request count and error rates
* Lambda invocation count, errors, duration, and throttles
* DynamoDB errors and throttles
* Step Functions execution status
* SQS queue depth
* DLQ depth
* MediaConvert job status
* MediaLive input and output health
* MediaPackage origin health
* CloudFront request count and error rates
* WAF blocked requests
* GuardDuty findings
* Estimated AWS cost

Trigger at least one non-production test alarm and verify that the approved notification channel receives it.

## 7.6 Client readiness

For all seven clients, record:

| Client   | Configuration updated | Authentication tested | VOD tested | Live tested | Subtitle tested | Status |
| -------- | --------------------- | --------------------- | ---------- | ----------- | --------------- | ------ |
| Client 1 |                       |                       |            |             |                 |        |
| Client 2 |                       |                       |            |             |                 |        |
| Client 3 |                       |                       |            |             |                 |        |
| Client 4 |                       |                       |            |             |                 |        |
| Client 5 |                       |                       |            |             |                 |        |
| Client 6 |                       |                       |            |             |                 |        |
| Client 7 |                       |                       |            |             |                 |        |

---

# 8. Cutover Day Procedure

## 8.1 Cutover opening

The Migration Lead must:

1. Open the approved communication channel.
2. Confirm all required team members are present.
3. Confirm the change record is open.
4. Confirm no conflicting production change is active.
5. Confirm the on-premises platform is healthy.
6. Confirm the AWS platform is healthy.
7. Confirm rollback remains available.
8. Record the official cutover start time.

### Cutover opening record

| Item                 | Result |
| -------------------- | ------ |
| Team present         |        |
| Change approved      |        |
| Change freeze active |        |
| On-premises healthy  |        |
| AWS healthy          |        |
| Monitoring active    |        |
| Rollback available   |        |
| Start time           |        |

---

## 8.2 Checkpoint 1 — Platform readiness

The Cloud Engineer, Security Lead, and Operations Lead must confirm:

* Infrastructure deployment is complete.
* No critical Terraform change remains pending.
* API, media, storage, and delivery services are operational.
* Monitoring and alarms are active.
* Security controls are active.
* No active critical incident exists.

**Decision:**

```text
GO / NO-GO
```

| Approver        | Decision | Time | Notes |
| --------------- | -------- | ---- | ----- |
| Cloud Engineer  |          |      |       |
| Security Lead   |          |      |       |
| Operations Lead |          |      |       |
| Migration Lead  |          |      |       |

---

## 8.3 Apply approved infrastructure changes

Only apply the previously reviewed plan:

```bash
terraform apply "production-cutover.tfplan"
```

Do not generate and immediately apply a new unreviewed production plan.

After completion:

```bash
terraform output
```

Record:

* API endpoint
* CloudFront distribution domain
* S3 bucket names
* DynamoDB table name
* Queue URLs
* State machine ARN
* Media service outputs

Verify that no unexpected resource was destroyed or replaced.

---

# 9. Final Media and Metadata Synchronization

## 9.1 Pause or control source changes

Before final synchronization:

* Pause non-essential VOD uploads.
* Pause metadata administration changes.
* Record all content created after the freeze.
* Keep the existing platform available for rollback.
* Do not delete source data.

## 9.2 Final media synchronization

Use the approved transfer method.

Example for an approved file-system-to-S3 transfer:

```bash
aws s3 sync \
  <SOURCE_MEDIA_PATH> \
  s3://<VOD_INGEST_BUCKET>/<MIGRATION_PREFIX>/ \
  --profile <PRODUCTION_PROFILE> \
  --region <PRIMARY_REGION>
```

For large or continuous transfers, execute the approved AWS DataSync task instead.

Record:

| Item                     | Value |
| ------------------------ | ----- |
| Transfer start           |       |
| Transfer end             |       |
| Source object count      |       |
| Destination object count |       |
| Source total size        |       |
| Destination total size   |       |
| Failed objects           |       |
| Retry result             |       |

## 9.3 Integrity verification

For each migration batch:

* Compare source and destination object counts.
* Compare file sizes.
* Compare checksums where available.
* Verify required object metadata.
* Verify encryption.
* Verify the destination storage class.
* Test representative files.

**Hard stop:** Do not continue when a critical media-integrity mismatch remains unresolved.

## 9.4 Final metadata synchronization

The Data Lead must:

1. Export records changed since the previous synchronization.
2. Transform records into the approved DynamoDB structure.
3. Import or update the records.
4. Compare record counts.
5. Validate required attributes.
6. Check media-object references.
7. Check subtitle-object references.
8. Record rejected or duplicate records.

### Metadata reconciliation

| Check                       |                 Expected | Actual | Status |
| --------------------------- | -----------------------: | -----: | ------ |
| Source records              |                          |        |        |
| Imported records            |                          |        |        |
| Rejected records            | 0 or approved exceptions |        |        |
| Duplicate IDs               |                        0 |        |        |
| Missing media references    |                        0 |        |        |
| Missing subtitle references | 0 or approved exceptions |        |        |

---

## 9.5 Checkpoint 2 — Synchronization complete

The Data Lead and Test Lead must approve:

* Media reconciliation
* Metadata reconciliation
* Sample playback
* Subtitle mapping
* Exception handling

**Decision:**

```text
GO / NO-GO
```

| Approver       | Decision | Time | Notes |
| -------------- | -------- | ---- | ----- |
| Data Lead      |          |      |       |
| Test Lead      |          |      |       |
| Migration Lead |          |      |       |

---

# 10. Pre-Traffic Functional Validation

## 10.1 F1 — Authentication and API

Execute:

* Successful user authentication
* Invalid-password rejection
* Expired-token rejection
* Unauthorized API rejection
* Metadata retrieval
* Playback authorization
* Subtitle-language selection
* API throttling test where safe

Example API health request:

```bash
curl --fail --silent --show-error \
  https://<API_DOMAIN>/<STAGE>/health
```

Expected result:

```text
HTTP 200
```

## 10.2 F2 — Live streaming

Confirm:

* Third-party encoder is connected.
* Both MediaLive pipelines are healthy.
* MediaLive output reaches MediaPackage.
* MediaPackage endpoint is healthy.
* CloudFront can retrieve the live stream.
* Audio and video are synchronized.
* Live latency is within the approved threshold.
* Dropped-frame alarms remain below threshold.

## 10.3 F3 — VOD processing

Upload an approved test object:

```bash
aws s3 cp \
  <TEST_VIDEO_FILE> \
  s3://<VOD_INGEST_BUCKET>/cutover-validation/ \
  --profile <PRODUCTION_PROFILE> \
  --region <PRIMARY_REGION>
```

Confirm:

1. EventBridge detects the object.
2. Step Functions starts.
3. MediaConvert starts and completes.
4. Output is written to the private VOD origin.
5. DynamoDB status is updated.
6. CloudFront delivers the media.
7. No message enters the DLQ.

## 10.4 F4 — Subtitle processing

Confirm:

* Transcription completes.
* Translation completes for required languages.
* Subtitle files are stored privately.
* DynamoDB language mapping is correct.
* CloudFront delivers the subtitle files.
* Subtitle timing is synchronized.

## 10.5 F5 — Content delivery

Confirm:

* CloudFront delivers VOD content.
* CloudFront delivers live content.
* CloudFront delivers subtitle files.
* Direct unauthorized S3 access is denied.
* Signed URLs or signed cookies expire as designed.
* Cache policies behave as expected.
* Geographic playback works from approved test locations.

## 10.6 F6 — Security and monitoring

Confirm:

* CloudTrail records the validation actions.
* CloudWatch receives logs and metrics.
* WAF logs requests.
* Config reports expected compliance status.
* GuardDuty has no unresolved critical finding.
* Alarm notifications reach the operations team.

---

## 10.7 Checkpoint 3 — Pre-traffic validation complete

| Area               | Owner                  | Result |
| ------------------ | ---------------------- | ------ |
| Authentication/API | Application Lead       |        |
| Live stream        | Media Engineer         |        |
| VOD processing     | Media Engineer         |        |
| Subtitles          | Application/Media Lead |        |
| Content delivery   | Cloud Engineer         |        |
| Security           | Security Lead          |        |
| Monitoring         | Operations Lead        |        |

**Decision:**

```text
GO / NO-GO
```

---

# 11. Production Traffic Migration

Use weighted Route 53 routing where supported. Where weighted routing is not practical, migrate the seven clients in controlled groups.

## 11.1 Recommended traffic stages

| Stage   | AWS traffic | On-premises traffic | Minimum observation |
| ------- | ----------: | ------------------: | ------------------: |
| Stage 1 |          5% |                 95% |          15 minutes |
| Stage 2 |         25% |                 75% |          20 minutes |
| Stage 3 |         50% |                                30 minutes |
| Stage 4 |         75% |                 25% |          30 minutes |
| Stage 5 |        100% |                  0% |          60 minutes |

Do not progress automatically. Each stage requires approval.

### Alternative client-group migration

| Stage   | Clients moved         |
| ------- | --------------------- |
| Stage 1 | Client 1              |
| Stage 2 | Clients 2–3           |
| Stage 3 | Clients 4–5           |
| Stage 4 | Clients 6–7           |
| Stage 5 | All clients confirmed |

## 11.2 At each stage

The Operations Lead must monitor:

* Authentication success
* API 4xx and 5xx errors
* API latency
* Lambda errors and throttles
* DynamoDB throttles
* Playback failures
* Playback start time
* CloudFront error rates
* MediaLive input health
* Dropped frames
* MediaPackage health
* MediaConvert failures
* Step Functions failures
* Queue depth
* DLQ depth
* WAF blocks
* GuardDuty findings

The Test Lead must validate:

* Login
* Metadata retrieval
* VOD playback
* Live playback
* Subtitle selection
* Protected-content access
* Reconnection behaviour

### Traffic-stage record

| Stage | Start | End | Metrics acceptable | Validation passed | Decision |
| ----- | ----- | --- | ------------------ | ----------------- | -------- |
| 5%    |       |     |                    |                   |          |
| 25%   |       |     |                    |                   |          |
| 50%   |       |     |                    |                   |          |
| 75%   |       |     |                    |                   |          |
| 100%  |       |     |                    |                   |          |

---

# 12. Go, Hold, and Rollback Rules

## 12.1 Continue to next stage

Continue only when:

* No rollback threshold has been reached.
* Warning conditions have been explained or resolved.
* Playback tests pass.
* Media and metadata remain consistent.
* Security controls remain active.
* The Operations Lead recommends continuation.
* The Migration Lead approves continuation.

## 12.2 Hold traffic progression

Hold at the current level when:

* A warning threshold is exceeded.
* A non-critical alarm is active.
* A limited client compatibility issue occurs.
* A processing backlog begins increasing.
* A temporary external dependency issue occurs.
* Additional evidence is required.

During a hold:

1. Do not increase AWS traffic.
2. Investigate the condition.
3. Record the cause.
4. Correct the issue where possible.
5. Repeat validation.
6. Continue or roll back based on the approved decision.

## 12.3 Immediate rollback conditions

Initiate immediate rollback or security isolation for:

* Unauthorized access to protected media
* Public exposure of a private bucket
* Confirmed metadata corruption
* Critical authentication outage
* Confirmed KMS access-control failure
* Critical GuardDuty finding related to the cutover
* Loss of required audit logging
* Repeated severe playback failure
* Sustained live-stream failure
* An incident that cannot be corrected within the approved cutover time

---

# 13. Rollback Procedure

## 13.1 Declare rollback

The Migration Lead must:

1. Announce rollback in the cutover communication channel.
2. Record the rollback start time.
3. Stop all traffic increases.
4. Assign an incident owner.
5. Preserve logs and evidence.
6. Notify the Business Owner and Security Lead.

## 13.2 Restore routing

Restore:

* Previous Route 53 records
* Previous DNS weights
* Previous application endpoint configuration
* Previous client routing configuration

Verify DNS:

```bash
nslookup <PRODUCTION_DOMAIN>
```

or:

```bash
dig <PRODUCTION_DOMAIN>
```

Expected result:

* The domain resolves to the previous approved endpoint.

## 13.3 Pause affected AWS ingestion

Depending on the failure:

* Disable the VOD EventBridge ingestion rule.
* Pause or restrict uploads to the ingest bucket.
* Stop new processing workflow executions.
* Set approved consumers to zero concurrency where appropriate.
* Stop or isolate the affected MediaLive channel when required.
* Do not delete queues or failed messages.
* Do not empty the DLQ.
* Do not delete newly created media or metadata.

Example EventBridge rule disablement:

```bash
aws events disable-rule \
  --name <VOD_INGESTION_RULE> \
  --profile <PRODUCTION_PROFILE> \
  --region <PRIMARY_REGION>
```

## 13.4 Validate the on-premises platform

Confirm:

* All required clients reconnect.
* Authentication works.
* Metadata is available.
* VOD playback works.
* Live playback works.
* No unresolved local-server failure exists.

## 13.5 Reconcile data created during cutover

Identify:

* New uploads
* Newly processed VOD files
* New metadata records
* Metadata updates
* New subtitle files
* Publication-status changes
* User or playback state requiring preservation

Create a reconciliation manifest containing:

| Item | AWS location | On-premises location | Required action | Status |
| ---- | ------------ | -------------------- | --------------- | ------ |
|      |              |                      |                 |        |

Do not discard AWS-created data until the Business Owner and Data Lead approve the disposition.

## 13.6 Preserve failure evidence

Preserve:

* CloudWatch logs
* CloudTrail events
* Step Functions execution history
* MediaConvert job results
* MediaLive and MediaPackage metrics
* SQS and DLQ messages
* WAF logs
* GuardDuty findings
* Terraform logs
* DNS change history
* Client error logs
* Screenshots and timestamps

## 13.7 Rollback completion

Rollback is complete when:

* Production traffic uses the previous environment.
* All required clients operate normally.
* New data has been identified.
* No active production-impacting AWS process remains uncontrolled.
* Stakeholders have been notified.
* The incident record is open.
* Corrective actions have been assigned.

### Rollback sign-off

| Role            | Approval | Time | Notes |
| --------------- | -------- | ---- | ----- |
| Migration Lead  |          |      |       |
| Operations Lead |          |      |       |
| Data Lead       |          |      |       |
| Security Lead   |          |      |       |
| Business Owner  |          |      |       |

---

# 14. Successful Cutover Completion

After 100% of production traffic has moved to AWS:

## 14.1 Minimum observation period

Observe the platform for at least:

```text
60 minutes at 100% traffic
```

The approved production observation period may be longer.

## 14.2 Final validation

Confirm:

* All seven clients operate through AWS.
* Authentication succeeds.
* API performance is acceptable.
* VOD playback succeeds.
* Live playback succeeds.
* Required subtitle languages work.
* Direct S3 origin access is blocked.
* No critical alarm is active.
* No unexpected DLQ growth exists.
* Security monitoring is operational.
* Media and metadata remain consistent.

## 14.3 Cutover completion record

| Item                    | Result |
| ----------------------- | ------ |
| 100% traffic time       |        |
| Observation completed   |        |
| Functional tests passed |        |
| Security tests passed   |        |
| Monitoring healthy      |        |
| Data reconciled         |        |
| Critical incidents      |        |
| Residual risks          |        |

### Final cutover approval

| Role            | Decision | Time |
| --------------- | -------- | ---- |
| Migration Lead  |          |      |
| Operations Lead |          |      |
| Security Lead   |          |      |
| Test Lead       |          |      |
| Business Owner  |          |      |

---

# 15. Stabilization Period

The proposed stabilization period is fourteen days.

## 15.1 Daily review

Review daily:

* Platform availability
* API latency and errors
* Playback failures
* Live-stream stability
* MediaConvert success rate
* Step Functions failures
* Queue and DLQ depth
* Subtitle-processing failures
* CloudFront cache-hit ratio
* WAF activity
* GuardDuty findings
* Configuration changes
* Estimated AWS cost
* Support incidents

## 15.2 Daily stabilization record

| Date | Availability | Playback | Processing | Security | Cost | Incidents | Owner |
| ---- | ------------ | -------- | ---------- | -------- | ---- | --------- | ----- |
|      |              |          |            |          |      |           |       |

## 15.3 Issue priorities

| Severity | Description                                  | Response                   |
| -------- | -------------------------------------------- | -------------------------- |
| Critical | Outage, data corruption, unauthorized access | Immediate response         |
| High     | Major degradation affecting multiple clients | Response within 30 minutes |
| Medium   | Limited failure with workaround              | Response within four hours |
| Low      | Minor defect or optimization item            | Add to backlog             |

---

# 16. Failed Queue and Workflow Recovery

## 16.1 DLQ handling

When a message appears in the VOD DLQ:

1. Record the message ID and timestamp.
2. Identify the related media object.
3. Review Step Functions and MediaConvert logs.
4. Determine whether the failure is temporary or permanent.
5. Correct the root cause.
6. Validate the object and configuration.
7. Redrive or resubmit the message.
8. Confirm successful processing.
9. Remove the resolved incident from the active queue.
10. Retain evidence.

Do not repeatedly redrive a message without identifying the failure cause.

## 16.2 Step Functions recovery

For failed executions:

* Review the failed state.
* Review retry attempts.
* Verify input data.
* Verify IAM permissions.
* Verify service quotas.
* Verify MediaConvert configuration.
* Start a new execution only after correcting the failure.

## 16.3 MediaConvert recovery

For failed jobs:

* Record the job ID.
* Review error codes.
* Validate source format.
* Validate IAM access.
* Validate output destination.
* Validate codec and resolution settings.
* Resubmit using an approved job template.

---

# 17. Incident Communication Templates

## 17.1 Cutover started

```text
Production cutover has started under change <CHANGE_ID>.

Start time: <TIME>
Current stage: Platform validation
Current production impact: <NONE/EXPECTED IMPACT>
Next update: <TIME>
```

## 17.2 Traffic stage completed

```text
AWS traffic stage <PERCENTAGE> has completed successfully.

Observation period: <DURATION>
Playback status: <STATUS>
API status: <STATUS>
Security status: <STATUS>
Decision: Proceeding to <NEXT_STAGE>
```

## 17.3 Cutover hold

```text
Production cutover is currently on hold.

Current AWS traffic: <PERCENTAGE>
Issue: <DESCRIPTION>
Customer impact: <DESCRIPTION>
Investigation owner: <OWNER>
Next decision time: <TIME>
```

## 17.4 Rollback initiated

```text
Rollback has been initiated for change <CHANGE_ID>.

Reason: <DESCRIPTION>
Rollback start time: <TIME>
Traffic is being restored to the previous production environment.
Further updates will be issued through <CHANNEL>.
```

## 17.5 Cutover completed

```text
Production cutover to AWS has completed successfully.

Completion time: <TIME>
AWS production traffic: 100%
Validation status: Passed
Stabilization period: <START_DATE> to <END_DATE>
Support channel: <CHANNEL>
```

---

# 18. Evidence Requirements

The following evidence must be retained:

* Approved change record
* Terraform plan and apply result
* AWS identity confirmation
* Infrastructure outputs
* Media reconciliation report
* Metadata reconciliation report
* API test results
* VOD test results
* Live-stream test results
* Subtitle test results
* Security validation results
* Monitoring screenshots
* CloudWatch alarm evidence
* DNS before-and-after evidence
* Traffic-stage approvals
* Incident and rollback records
* Final sign-off

Evidence storage location:

```text
TBD
```

Evidence must not contain credentials, tokens, private keys, or unnecessary personal information.

---

# 19. On-Premises Decommissioning Restrictions

The existing server must not be decommissioned immediately after cutover.

Decommissioning may begin only when:

* The stabilization period has completed.
* No unresolved critical incident exists.
* The rollback window has expired.
* Final media reconciliation has passed.
* Final metadata reconciliation has passed.
* Backup requirements have been met.
* Retention requirements have been met.
* Business Owner approval has been recorded.
* Security Lead approval has been recorded.

The decommissioning procedure must include:

1. Final backup
2. Final reconciliation
3. Log export
4. Credential revocation
5. Network isolation
6. Secure data deletion
7. Asset inventory update
8. Documentation update
9. Formal closure approval

---

# 20. Final Checklist

## Before cutover

* [ ] Change approved
* [ ] Required roles present
* [ ] AWS account and Region confirmed
* [ ] Infrastructure plan reviewed
* [ ] Security controls active
* [ ] Monitoring active
* [ ] Backups current
* [ ] DNS configuration recorded
* [ ] Rollback tested
* [ ] Client tests passed
* [ ] Change freeze active

## During cutover

* [ ] Final media synchronization complete
* [ ] Final metadata synchronization complete
* [ ] Integrity checks passed
* [ ] Pre-traffic validation passed
* [ ] Traffic stages approved
* [ ] Metrics monitored
* [ ] Evidence captured
* [ ] Stakeholders updated

## After cutover

* [ ] 100% traffic confirmed
* [ ] Observation period completed
* [ ] Functional validation passed
* [ ] Security validation passed
* [ ] Monitoring healthy
* [ ] Residual risks recorded
* [ ] Stabilization period started
* [ ] Final approval recorded

---

# 21. Runbook Approval

| Role             | Name | Decision | Date | Signature or record |
| ---------------- | ---- | -------- | ---- | ------------------- |
| Migration Lead   |      |          |      |                     |
| Cloud Engineer   |      |          |      |                     |
| Media Engineer   |      |          |      |                     |
| Application Lead |      |          |      |                     |
| Security Lead    |      |          |      |                     |
| Operations Lead  |      |          |      |                     |
| Test Lead        |      |          |      |                     |
| Business Owner   |      |          |      |                     |
