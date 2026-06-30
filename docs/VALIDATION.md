# AWS Media Platform Validation Plan

**Document version:** 0.1
**Status:** Draft
**Last updated:** YYYY-MM-DD
**Document owner:** Test Lead
**Review frequency:** Before pilot, before production cutover, and after major architecture changes

**Related documents:**

* `README.md`
* `docs/MIGRATION_PLAN.md`
* `docs/RUNBOOK.md`
* `docs/SECURITY.md`
* `infrastructure/`

---

# 1. Purpose

This document defines how the migrated AWS media platform will be tested and validated before production cutover, during production traffic migration, and throughout the stabilization period.

The validation process must demonstrate that:

1. Users can authenticate and access authorized services.
2. Application APIs function correctly.
3. Live streams can be ingested, processed, packaged, and delivered.
4. VOD content can be uploaded, processed, stored, and played.
5. Subtitle transcription and translation workflows operate correctly.
6. Media and subtitle content can be delivered securely through CloudFront.
7. Migrated media files and metadata remain complete and accurate.
8. Security controls prevent unauthorized access.
9. Monitoring and alerting identify operational and security failures.
10. Backup, restoration, cutover, and rollback procedures function as designed.
11. Platform performance and availability meet approved targets.
12. Operating costs remain within approved thresholds.

This document defines validation requirements and expected evidence. Exact production execution steps are maintained in `docs/RUNBOOK.md`.

---

# 2. Validation Principles

The project follows these validation principles.

## 2.1 Evidence-based acceptance

A control or feature is not considered validated solely because it appears in an architecture diagram or Infrastructure as Code template.

Validation requires evidence such as:

* Test output
* AWS service status
* Logs
* Metrics
* Screenshots
* Execution history
* Object counts
* Checksums
* Playback results
* Approved sign-off

## 2.2 Positive and negative testing

Testing must confirm both:

* Expected operations succeed.
* Unauthorized, invalid, or failed operations are rejected or handled safely.

## 2.3 Production-like testing

Pilot and staging environments should resemble production closely enough to provide reliable results.

## 2.4 Repeatability

Tests should be repeatable and documented so that they can be rerun after:

* Infrastructure changes
* Security changes
* Application updates
* Service incidents
* Recovery exercises

## 2.5 Traceability

Each test must map to:

* A business requirement
* An architecture flow
* A security control
* A migration phase
* A runbook checkpoint where applicable

## 2.6 Separation of test and production data

Production data should not be used in lower environments unless it has been approved, minimized, and anonymized where required.

---

# 3. Validation Scope

## 3.1 In scope

Validation applies to the following architecture flows.

| Flow | Function                           | Primary services                                      |
| ---- | ---------------------------------- | ----------------------------------------------------- |
| F1   | Authentication and application API | Route 53, API Gateway, WAF, Cognito, Lambda, DynamoDB |
| F2   | Live-stream processing             | MediaLive, Transcribe Live, Translate, MediaPackage   |
| F3   | VOD processing                     | S3, EventBridge, Step Functions, SQS, MediaConvert    |
| F4   | Subtitle processing                | Transcribe, Translate, S3, DynamoDB                   |
| F5   | Content delivery                   | CloudFront, MediaPackage, S3, Origin Access Control   |
| F6   | Security and monitoring            | WAF, KMS, CloudWatch, CloudTrail, Config, GuardDuty   |

Validation also covers:

* Media migration
* Metadata migration
* Client compatibility
* Infrastructure deployment
* Cutover
* Rollback
* Backup and restoration
* Cost monitoring
* Stabilization

## 3.2 Out of scope

Unless separately approved, the following are outside the initial validation scope:

* Digital-rights-management systems
* Recommendation engines
* Advertising platforms
* Third-party systems not integrated with the AWS platform
* Full regulatory certification
* Multi-Region active-active failover
* Penetration testing of third-party infrastructure without permission
* Client-device hardware certification

---

# 4. Validation Objectives

The validation objectives are to confirm:

| Objective ID | Objective                                                  |
| ------------ | ---------------------------------------------------------- |
| OBJ-01       | The platform supports all approved client functions        |
| OBJ-02       | The platform meets agreed availability and latency targets |
| OBJ-03       | Media assets and metadata remain accurate after migration  |
| OBJ-04       | Live and VOD workflows complete reliably                   |
| OBJ-05       | Required subtitle languages are available and synchronized |
| OBJ-06       | Private origins cannot be accessed directly                |
| OBJ-07       | Unauthorized requests are rejected                         |
| OBJ-08       | Security controls generate expected evidence               |
| OBJ-09       | Operational failures trigger alerts                        |
| OBJ-10       | Failed workflows can be diagnosed and recovered            |
| OBJ-11       | Rollback can restore the previous environment              |
| OBJ-12       | Costs remain within approved thresholds                    |

---

# 5. Roles and Responsibilities

| Role                  | Validation responsibility                                |
| --------------------- | -------------------------------------------------------- |
| Test Lead             | Owns the validation plan and final test report           |
| Migration Lead        | Coordinates validation with migration phases             |
| Cloud Engineer        | Supports infrastructure and delivery tests               |
| Application Lead      | Supports API, Cognito, Lambda, and DynamoDB tests        |
| Media Engineer        | Supports MediaLive, MediaPackage, and MediaConvert tests |
| Data Lead             | Performs file and metadata reconciliation                |
| Security Lead         | Approves and reviews security validation                 |
| Operations Lead       | Validates monitoring, alarms, and operational recovery   |
| Business Owner        | Approves user acceptance and business outcomes           |
| Client Representative | Confirms client-device behavior where required           |
| Change Manager        | Confirms production validation approvals are recorded    |

---

# 6. Required Decisions and Test Parameters

The following values must be finalized before the production validation cycle.

| Parameter                          |               Proposed value | Final value      |
| ---------------------------------- | ---------------------------: | ---------------- |
| Primary AWS Region                 | Based on client requirements | TBD              |
| Supported client devices           |       Seven existing clients | TBD details      |
| Supported browsers or players      |              Project-defined | TBD              |
| Supported video formats            |              Project-defined | TBD              |
| Supported codecs                   |              Project-defined | TBD              |
| Supported resolutions              |              Project-defined | TBD              |
| Supported subtitle formats         |    WebVTT or approved format | TBD              |
| Required subtitle languages        |               Client-defined | TBD              |
| Peak concurrent viewers            |     Based on expected demand | TBD              |
| API p95 latency                    |    Less than 800 ms proposed | TBD              |
| API p99 latency                    |  Less than 1,500 ms proposed | TBD              |
| Playback start time                | Less than 5 seconds proposed | TBD              |
| Live-stream latency                |       Architecture-dependent | TBD              |
| Playback failure rate              |        Less than 2% proposed | TBD              |
| API 5xx rate                       |        Less than 1% proposed | TBD              |
| CloudFront 5xx rate                |        Less than 1% proposed | TBD              |
| Availability target                |               At least 99.9% | TBD confirmation |
| RTO                                |               Client-defined | TBD              |
| RPO                                |               Client-defined | TBD              |
| Stabilization period               |             14 days proposed | TBD              |
| Monthly budget threshold           |              Client-approved | TBD              |
| Maximum defect severity at cutover |     No open Critical defects | Proposed         |

---

# 7. Validation Environments

## 7.1 Development

Used for:

* Unit testing
* Initial Lambda testing
* Workflow development
* Infrastructure development
* Developer debugging

Production data must not be used.

## 7.2 Test

Used for:

* Functional testing
* Integration testing
* Negative testing
* Security control testing
* Workflow failure testing

## 7.3 Staging

Used for:

* End-to-end validation
* Load testing
* Cutover rehearsal
* Rollback rehearsal
* User acceptance testing

The staging environment should resemble production in:

* Service configuration
* IAM structure
* Logging
* WAF
* CloudFront
* Workflow design
* Monitoring

## 7.4 Production

Production testing is limited to:

* Approved smoke tests
* Controlled traffic validation
* Monitoring checks
* Cutover checkpoints
* Post-cutover validation

Destructive testing must not be performed in production unless specifically approved.

---

# 8. Entry Criteria

A validation phase may begin when:

* [ ] Required infrastructure is deployed.
* [ ] Infrastructure validation has passed.
* [ ] Required IAM roles are available.
* [ ] Test accounts and identities exist.
* [ ] Test media files are available.
* [ ] Test metadata is available.
* [ ] Monitoring is active.
* [ ] Required endpoints are available.
* [ ] Test data is approved.
* [ ] Known blocking defects are resolved.
* [ ] Test owners are assigned.
* [ ] Required architecture decisions are documented.

---

# 9. Exit Criteria

The platform may be recommended for production cutover when:

* [ ] All Critical test cases pass.
* [ ] All High-priority test cases pass or have approved exceptions.
* [ ] No Critical defect remains open.
* [ ] No unapproved High-severity security finding remains open.
* [ ] Media migration reconciliation passes.
* [ ] Metadata reconciliation passes.
* [ ] Live and VOD playback tests pass.
* [ ] Required subtitle tests pass.
* [ ] Security validation passes.
* [ ] Monitoring and alerting tests pass.
* [ ] Backup and restoration tests pass.
* [ ] Rollback rehearsal passes.
* [ ] Performance targets are met.
* [ ] Cost estimates are approved.
* [ ] Business acceptance is recorded.

---

# 10. Test Data

## 10.1 Required media test set

The test set should contain:

* Short video
* Long video
* Small file
* Large file
* Multiple resolutions
* Multiple bitrates
* Supported codecs
* Unsupported codec
* Corrupted file
* File with audio
* File without audio
* File with existing subtitles
* File requiring transcription
* File with multilingual dialogue where applicable
* Live-stream test input

## 10.2 Metadata test set

Include:

* Valid media record
* Missing optional field
* Missing mandatory field
* Duplicate media identifier
* Invalid S3 object reference
* Invalid subtitle reference
* Unsupported language code
* Expired publication status
* Restricted content record
* Public content record

## 10.3 Identity test set

Include:

* Valid authenticated viewer
* Invalid user
* Disabled user
* Expired token
* User without playback permission
* Content operator
* Media administrator
* Read-only auditor
* Privileged administrator

## 10.4 Data-handling requirements

Test data must:

* Avoid unnecessary personal information.
* Be stored only in approved locations.
* Be removed after the approved retention period.
* Not contain production credentials or secrets.
* Be classified according to `SECURITY.md`.

---

# 11. Evidence Requirements

Each test record must include:

| Field           | Required content                      |
| --------------- | ------------------------------------- |
| Test ID         | Unique identifier                     |
| Requirement     | Requirement being validated           |
| Environment     | Test, staging, or production          |
| Tester          | Person performing the test            |
| Date and time   | Execution timestamp                   |
| Preconditions   | Required state before testing         |
| Procedure       | Exact test steps                      |
| Expected result | Required outcome                      |
| Actual result   | Observed outcome                      |
| Status          | Pass, Fail, Blocked, or Not Tested    |
| Evidence        | Logs, metrics, screenshots, or output |
| Defect ID       | Linked defect where applicable        |
| Reviewer        | Person confirming the result          |

Evidence must not expose:

* Passwords
* Access keys
* Tokens
* Private keys
* Unnecessary personal data
* Sensitive client-identifying information

---

# 12. Test Status Definitions

| Status                 | Meaning                                          |
| ---------------------- | ------------------------------------------------ |
| Pass                   | Actual result matches the expected result        |
| Fail                   | Actual result does not meet the requirement      |
| Blocked                | Test cannot proceed because of another issue     |
| Not Tested             | Test has not been executed                       |
| Conditionally Accepted | Approved exception or temporary risk acceptance  |
| Not Applicable         | Requirement does not apply to the approved scope |

---

# 13. Defect Severity

| Severity | Description                                                            | Cutover impact                  |
| -------- | ---------------------------------------------------------------------- | ------------------------------- |
| Critical | Outage, data corruption, unauthorized access, or unrecoverable failure | Blocks cutover                  |
| High     | Major function unavailable or serious security weakness                | Normally blocks cutover         |
| Medium   | Limited failure with a practical workaround                            | Requires review                 |
| Low      | Minor defect or usability issue                                        | Does not normally block cutover |

## 13.1 Critical defect examples

* Private S3 media is publicly accessible.
* Users cannot authenticate.
* Metadata is corrupted.
* Live playback consistently fails.
* VOD processing cannot complete.
* CloudTrail does not record required events.
* Rollback cannot restore service.
* Encryption keys prevent recovery.
* Unauthorized users can access protected content.

## 13.2 Defect workflow

1. Record the defect.
2. Assign severity.
3. Assign an owner.
4. Identify affected tests.
5. Correct the issue.
6. Retest.
7. Perform regression testing.
8. Close or formally accept the defect.

---

# 14. Functional Validation Matrix

| Test group                       | Flow          | Priority |
| -------------------------------- | ------------- | -------- |
| Authentication and authorization | F1            | Critical |
| API behavior                     | F1            | Critical |
| Live-stream workflow             | F2            | Critical |
| VOD workflow                     | F3            | Critical |
| Subtitle workflow                | F4            | High     |
| Content delivery                 | F5            | Critical |
| Security and monitoring          | F6            | Critical |
| Data migration                   | Cross-cutting | Critical |
| Backup and recovery              | Cross-cutting | Critical |
| Performance and cost             | Cross-cutting | High     |

---

# 15. F1 — Authentication and API Validation

## VAL-F1-001 — Successful Authentication

**Priority:** Critical

**Preconditions:**

* Cognito user exists.
* User is active.
* Correct credentials are available.

**Procedure:**

1. Open the approved client.
2. Enter valid credentials.
3. Complete MFA where required.
4. Request an authenticated API function.

**Expected result:**

* Authentication succeeds.
* A valid token is issued.
* The protected API accepts the token.
* Authentication activity is logged.

**Evidence:**

* Client result
* Cognito log or event evidence
* API access log

---

## VAL-F1-002 — Invalid Password Rejection

**Priority:** High

**Procedure:**

1. Enter a valid username.
2. Enter an incorrect password.
3. Attempt authentication.

**Expected result:**

* Authentication is rejected.
* No valid token is issued.
* The response does not reveal unnecessary account details.
* The failure is visible in approved monitoring where configured.

---

## VAL-F1-003 — Expired Token Rejection

**Priority:** Critical

**Procedure:**

1. Obtain an authenticated token.
2. Wait for expiry or use an approved expired test token.
3. Call a protected API.

**Expected result:**

* The API rejects the request.
* No protected data is returned.
* The response uses the approved status code.

---

## VAL-F1-004 — Unauthorized Role Rejection

**Priority:** Critical

**Procedure:**

1. Authenticate as a standard viewer.
2. Attempt an administrative action.

**Expected result:**

* Access is denied.
* No administrative change occurs.
* The attempt is logged.

---

## VAL-F1-005 — Metadata Retrieval

**Priority:** Critical

**Procedure:**

1. Authenticate as an authorized viewer.
2. Request an approved media record.
3. Review the response.

**Expected result:**

* Correct metadata is returned.
* No unauthorized fields are exposed.
* The response meets latency requirements.

---

## VAL-F1-006 — Playback Authorization

**Priority:** Critical

**Procedure:**

1. Authenticate as an authorized viewer.
2. Request access to protected content.
3. Use the returned playback authorization.

**Expected result:**

* Access is granted only to approved content.
* Authorization expires as designed.
* Direct access without authorization fails.

---

## VAL-F1-007 — API Request Validation

**Priority:** High

**Procedure:**

Submit requests containing:

* Missing mandatory fields
* Invalid data types
* Oversized values
* Invalid language codes
* Invalid media IDs

**Expected result:**

* Invalid requests are rejected safely.
* No internal error details are exposed.
* No unauthorized data change occurs.

---

## VAL-F1-008 — API Throttling

**Priority:** High

**Procedure:**

1. Send requests above the approved test rate.
2. Observe API behavior.

**Expected result:**

* Requests above the approved threshold are throttled.
* The platform remains available.
* Throttling is visible in metrics and logs.

---

# 16. F2 — Live-Stream Validation

## VAL-F2-001 — Live Encoder Connection

**Priority:** Critical

**Procedure:**

1. Start the approved live encoder.
2. Connect to the MediaLive input.
3. Confirm input detection.

**Expected result:**

* MediaLive receives the stream.
* Input health is normal.
* No unauthorized source can connect.

---

## VAL-F2-002 — Dual-Pipeline Operation

**Priority:** Critical

**Procedure:**

1. Start the MediaLive Standard channel.
2. Confirm both pipelines are active.
3. Review output metrics.

**Expected result:**

* Both pipelines process the live stream.
* Outputs reach the approved destination.
* No pipeline-specific error remains active.

---

## VAL-F2-003 — MediaPackage Delivery

**Priority:** Critical

**Procedure:**

1. Confirm MediaLive output is active.
2. Request the MediaPackage endpoint through the approved delivery path.
3. Play the live stream.

**Expected result:**

* MediaPackage receives the stream.
* A valid stream is available.
* Playback succeeds through CloudFront.

---

## VAL-F2-004 — Live Pipeline Failure

**Priority:** Critical

**Procedure:**

1. Operate both live pipelines.
2. Simulate or safely trigger one pipeline failure.
3. Monitor playback and alarms.

**Expected result:**

* The remaining pipeline continues service where supported.
* The failure generates an alarm.
* Playback impact remains within the approved threshold.

---

## VAL-F2-005 — Encoder Input Interruption

**Priority:** High

**Procedure:**

1. Start a live stream.
2. Interrupt the encoder input.
3. Restore the input.

**Expected result:**

* Input loss is detected.
* An alarm is generated.
* Recovery occurs according to the approved design.
* The event is logged.

---

## VAL-F2-006 — Live Playback Compatibility

**Priority:** Critical

Test live playback on:

* All seven approved clients
* Approved browsers or players
* Approved networks
* Approved locations

**Expected result:**

* Video plays correctly.
* Audio remains synchronized.
* Playback controls operate as expected.
* No unsupported-client issue remains unresolved.

---

## VAL-F2-007 — Live Subtitle Validation

**Priority:** High or Not Applicable

Where live subtitles are in scope:

* Confirm transcription.
* Confirm translation.
* Confirm packaging.
* Confirm language selection.
* Confirm synchronization.

If live subtitles are deferred, record the test as Not Applicable with approved scope evidence.

---

# 17. F3 — VOD Processing Validation

## VAL-F3-001 — Successful VOD Processing

**Priority:** Critical

**Preconditions:**

* Test S3 ingest bucket is available.
* EventBridge rule is enabled.
* Step Functions workflow is deployed.
* MediaConvert is available.

**Procedure:**

1. Upload an approved test video.
2. Confirm EventBridge detects the object.
3. Confirm Step Functions starts.
4. Confirm MediaConvert begins.
5. Wait for completion.
6. Confirm output is stored in the VOD origin.
7. Confirm metadata status is updated.
8. Play the output through CloudFront.

**Expected result:**

* Processing completes successfully.
* A valid playback manifest is produced.
* The media plays through CloudFront.
* No message appears in the DLQ.

**Evidence:**

* S3 object details
* EventBridge evidence
* Step Functions execution
* MediaConvert result
* DynamoDB result
* Playback evidence

---

## VAL-F3-002 — Unsupported Format

**Priority:** High

**Procedure:**

1. Upload a file using an unsupported format.
2. Observe the workflow.

**Expected result:**

* The file is rejected or quarantined.
* It is not published.
* The failure reason is recorded.
* The system remains stable.

---

## VAL-F3-003 — Corrupted Media File

**Priority:** High

**Procedure:**

1. Upload an intentionally corrupted media file.
2. Observe validation and processing.

**Expected result:**

* The file does not become published content.
* Processing fails safely.
* Failure evidence is retained.
* A retry loop does not continue indefinitely.

---

## VAL-F3-004 — Step Functions Retry

**Priority:** High

**Procedure:**

1. Trigger a temporary, controlled workflow failure.
2. Observe retry behavior.

**Expected result:**

* The workflow retries according to policy.
* Retry count and delay match the approved design.
* Processing succeeds when the temporary issue is removed.

---

## VAL-F3-005 — Retry Exhaustion and Failure Handling

**Priority:** Critical

**Procedure:**

1. Trigger a persistent controlled failure.
2. Allow retries to be exhausted.
3. Review failure handling.

**Expected result:**

* The workflow enters the approved failure path.
* The item is not published.
* Failure evidence is retained.
* An alert is generated.
* The DLQ or approved failure destination receives the item where designed.

---

## VAL-F3-006 — DLQ Redrive

**Priority:** High

**Procedure:**

1. Place an approved failed message into the DLQ.
2. Correct the root cause.
3. Perform the approved redrive or resubmission.
4. Verify completion.

**Expected result:**

* The content processes successfully.
* The message is not duplicated.
* Metadata is updated correctly.
* Evidence is recorded.

---

## VAL-F3-007 — Duplicate Upload

**Priority:** Medium

**Procedure:**

Upload the same object or media identifier twice.

**Expected result:**

* The approved duplicate-handling rule is applied.
* Duplicate content is not unintentionally published.
* Metadata remains consistent.

---

## VAL-F3-008 — Large File Processing

**Priority:** High

**Procedure:**

1. Upload a file near the approved maximum size.
2. Monitor processing time and service behavior.

**Expected result:**

* Processing completes within the approved limit.
* No timeout or uncontrolled retry occurs.
* Output is playable.

---

# 18. F4 — Subtitle Validation

## VAL-F4-001 — Successful Transcription

**Priority:** High

**Procedure:**

1. Submit approved source media.
2. Start transcription.
3. Review output.

**Expected result:**

* Transcription completes.
* Output is stored privately.
* Metadata references the correct object.
* Required character encoding is preserved.

---

## VAL-F4-002 — Successful Translation

**Priority:** High

**Procedure:**

1. Use a completed transcription.
2. Translate into each required language.
3. Review translated output.

**Expected result:**

* Translation completes.
* Each language has a unique valid mapping.
* Output is stored privately.

---

## VAL-F4-003 — Subtitle Synchronization

**Priority:** Critical where subtitles are required

**Procedure:**

1. Play test content.
2. Enable each subtitle language.
3. Compare subtitle timing with dialogue.

**Expected result:**

* Subtitles remain acceptably synchronized.
* No persistent timing drift exists.
* Language selection works correctly.

---

## VAL-F4-004 — Missing Subtitle Language

**Priority:** Medium

**Procedure:**

1. Request a language that is not available.
2. Observe application behavior.

**Expected result:**

* The request fails gracefully or falls back according to policy.
* An incorrect language file is not returned.
* No internal object path is exposed.

---

## VAL-F4-005 — Unauthorized Subtitle Replacement

**Priority:** Critical

**Procedure:**

1. Use an unauthorized identity.
2. Attempt to replace a subtitle file.

**Expected result:**

* Access is denied.
* The original subtitle remains unchanged.
* The attempt is logged.

---

## VAL-F4-006 — Subtitle Delivery Through CloudFront

**Priority:** High

**Procedure:**

1. Request a subtitle through the approved CloudFront path.
2. Attempt direct S3 access.

**Expected result:**

* CloudFront delivery succeeds.
* Direct unauthorized S3 access fails.

---

# 19. F5 — Content Delivery Validation

## VAL-F5-001 — VOD Delivery Through CloudFront

**Priority:** Critical

**Procedure:**

1. Request approved VOD content.
2. Play the media.
3. Review CloudFront response and metrics.

**Expected result:**

* Content is delivered successfully.
* Playback begins within the approved target.
* No origin error occurs.

---

## VAL-F5-002 — Live Delivery Through CloudFront

**Priority:** Critical

**Procedure:**

1. Start a live stream.
2. Request it through CloudFront.
3. Monitor playback.

**Expected result:**

* Live playback succeeds.
* Latency remains within the approved target.
* The MediaPackage origin remains healthy.

---

## VAL-F5-003 — Direct S3 Access Denial

**Priority:** Critical

**Procedure:**

1. Identify a private origin object.
2. Attempt to access it directly without approved authorization.

**Expected result:**

* Direct access is denied.
* The object remains available through the approved CloudFront path.

---

## VAL-F5-004 — Signed URL Expiry

**Priority:** Critical where signed URLs are selected

**Procedure:**

1. Generate a valid signed URL.
2. Access the content before expiry.
3. Access the same URL after expiry.

**Expected result:**

* Access succeeds before expiry.
* Access fails after expiry.

---

## VAL-F5-005 — Signed Cookie Expiry

**Priority:** Critical where signed cookies are selected

**Procedure:**

1. Obtain a valid signed cookie.
2. Access approved streaming assets.
3. Repeat after expiry.

**Expected result:**

* Approved assets are available before expiry.
* Access is denied after expiry.

---

## VAL-F5-006 — Cache Behavior

**Priority:** High

**Procedure:**

1. Request an object for the first time.
2. Repeat the request.
3. Review cache metrics and headers.

**Expected result:**

* Cache miss and hit behavior match the approved policy.
* Protected content is not cached incorrectly.
* Updated content follows the approved invalidation or versioning method.

---

## VAL-F5-007 — Origin Failure Behavior

**Priority:** High

**Procedure:**

1. Simulate an approved origin error in staging.
2. Request content through CloudFront.

**Expected result:**

* The platform returns the approved error behavior.
* Monitoring detects the condition.
* No unrelated private information is exposed.

---

# 20. F6 — Security and Monitoring Validation

## VAL-F6-001 — WAF SQL Injection Protection

**Priority:** Critical

**Procedure:**

1. Send an approved non-destructive SQL-injection test string to the protected API.
2. Review the response and WAF logs.

**Expected result:**

* The request is counted or blocked according to the approved rule mode.
* The event appears in WAF evidence.
* The backend does not process malicious input.

---

## VAL-F6-002 — WAF Cross-Site Scripting Protection

**Priority:** High

**Procedure:**

1. Send an approved non-destructive XSS test string.
2. Review WAF behavior.

**Expected result:**

* The request is handled according to the approved WAF rule.
* No unsafe application behavior occurs.

---

## VAL-F6-003 — WAF Rate-Based Rule

**Priority:** High

**Procedure:**

1. Generate requests above the approved rate threshold.
2. Observe WAF behavior.

**Expected result:**

* Excess traffic is counted or blocked.
* Normal test traffic remains available.
* Evidence is recorded.

---

## VAL-F6-004 — CloudTrail Recording

**Priority:** Critical

**Procedure:**

1. Perform an approved administrative action.
2. Search CloudTrail for the event.

**Expected result:**

* The action is recorded.
* The event identifies the actor, time, Region, and action.
* The log is stored in the approved location.

---

## VAL-F6-005 — CloudTrail Protection

**Priority:** Critical

**Procedure:**

1. Use an unauthorized test role.
2. Attempt to disable or modify CloudTrail.

**Expected result:**

* Access is denied.
* The attempt is logged or alerted.

---

## VAL-F6-006 — AWS Config Detection

**Priority:** High

**Procedure:**

1. Create or simulate an approved non-compliant test resource in a non-production environment.
2. Wait for Config evaluation.

**Expected result:**

* The resource is identified as non-compliant.
* Evidence is available.
* Notification occurs where configured.

---

## VAL-F6-007 — GuardDuty Finding Routing

**Priority:** High

**Procedure:**

1. Use an approved GuardDuty sample finding.
2. Confirm routing to the security channel.

**Expected result:**

* The sample finding appears.
* The alert reaches the approved recipient.
* The incident process can be initiated.

---

## VAL-F6-008 — S3 Public Access Prevention

**Priority:** Critical

**Procedure:**

1. Use an unauthorized role.
2. Attempt to make a protected bucket or object public.

**Expected result:**

* The action is denied or detected immediately.
* The resource remains private.
* Evidence is recorded.

---

## VAL-F6-009 — KMS Access Denial

**Priority:** Critical

**Procedure:**

1. Use a role without decrypt permission.
2. Attempt to access encrypted data.

**Expected result:**

* Decryption is denied.
* Data is not returned.
* The event is logged.

---

## VAL-F6-010 — Secret Access Restriction

**Priority:** Critical

**Procedure:**

1. Use an unauthorized role.
2. Attempt to retrieve a production secret.

**Expected result:**

* Access is denied.
* The secret value is not exposed.
* The attempt is recorded.

---

## VAL-F6-011 — Break-Glass Role Monitoring

**Priority:** High

**Procedure:**

1. Assume the break-glass role using the approved test process.
2. Review alerts and logs.

**Expected result:**

* Role assumption generates immediate evidence or notification.
* The session is traceable.
* Post-use review can be completed.

---

# 21. Data Migration Validation

## VAL-DATA-001 — Object Count Reconciliation

**Priority:** Critical

**Procedure:**

1. Record source object count.
2. Record destination object count.
3. Compare results.

**Expected result:**

* Counts match or approved exceptions are documented.

---

## VAL-DATA-002 — File Checksum Validation

**Priority:** Critical

**Procedure:**

1. Generate or retrieve source checksums.
2. Generate or retrieve destination checksums.
3. Compare values.

**Expected result:**

* Required checksums match.
* Mismatched files are quarantined and reprocessed.

---

## VAL-DATA-003 — File Size Reconciliation

**Priority:** High

**Procedure:**

Compare source and destination file sizes.

**Expected result:**

* Sizes match except where approved transformation occurred.

---

## VAL-DATA-004 — Metadata Record Count

**Priority:** Critical

**Procedure:**

1. Count approved source metadata records.
2. Count migrated DynamoDB records.
3. Compare results.

**Expected result:**

* Counts reconcile.
* Exceptions are documented.

---

## VAL-DATA-005 — Metadata Referential Integrity

**Priority:** Critical

Validate that:

* Every published media record references a valid media object.
* Every subtitle reference points to an existing subtitle object.
* Every language code is valid.
* No duplicate primary identifier exists.

---

## VAL-DATA-006 — Representative Playback

**Priority:** Critical

Select media from:

* Frequently accessed content
* Archival content
* Multiple formats
* Multiple resolutions
* Multiple subtitle languages

**Expected result:**

* Representative content plays correctly.

---

## VAL-DATA-007 — Incremental Synchronization

**Priority:** Critical

**Procedure:**

1. Create or update approved source data after the main migration batch.
2. Execute incremental synchronization.
3. Reconcile the result.

**Expected result:**

* Only required changes are transferred.
* No record is lost or duplicated.

---

# 22. Performance and Load Validation

## 22.1 Performance targets

| Metric                |                     Proposed target | Final target |
| --------------------- | ----------------------------------: | ------------ |
| API p50 latency       |                    Less than 300 ms | TBD          |
| API p95 latency       |                    Less than 800 ms | TBD          |
| API p99 latency       |                  Less than 1,500 ms | TBD          |
| VOD playback start    |                 Less than 5 seconds | TBD          |
| Live playback start   |                 Less than 8 seconds | TBD          |
| API 5xx rate          |                        Less than 1% | TBD          |
| CloudFront 5xx rate   |                        Less than 1% | TBD          |
| Playback failure rate |                        Less than 2% | TBD          |
| VOD processing time   | Based on media duration and profile | TBD          |
| Live latency          |    Based on selected packaging mode | TBD          |

## VAL-PERF-001 — API Baseline

Measure:

* Request count
* p50 latency
* p95 latency
* p99 latency
* 4xx rate
* 5xx rate

**Expected result:**

* Results meet approved targets.

---

## VAL-PERF-002 — Concurrent Viewer Load

**Procedure:**

1. Generate approved simulated viewer traffic.
2. Increase load gradually.
3. Monitor CloudFront, API Gateway, Lambda, and DynamoDB.

**Expected result:**

* The platform supports approved expected load.
* No uncontrolled throttling occurs.
* Error rates remain within thresholds.

---

## VAL-PERF-003 — Sudden Traffic Increase

**Procedure:**

1. Establish baseline traffic.
2. Introduce an approved rapid traffic increase.
3. Monitor scaling and error rates.

**Expected result:**

* The platform scales without unacceptable interruption.
* Alarms identify abnormal conditions.

---

## VAL-PERF-004 — VOD Processing Concurrency

**Procedure:**

1. Upload multiple approved files.
2. Observe workflow concurrency.
3. Monitor MediaConvert, Step Functions, SQS, and DynamoDB.

**Expected result:**

* Jobs are processed according to the approved design.
* Queue growth remains manageable.
* Failures are handled correctly.

---

# 23. Availability and Resilience Validation

## VAL-RES-001 — MediaLive Pipeline Failure

Validate continuity when one pipeline fails.

## VAL-RES-002 — Lambda Failure Handling

Trigger an approved Lambda failure and confirm:

* Error logging
* Workflow retry
* Failure notification
* Safe termination

## VAL-RES-003 — Queue Backlog

Generate an approved temporary backlog and confirm:

* Queue metrics increase.
* Alarms activate.
* Processing recovers after the condition is removed.

## VAL-RES-004 — DLQ Alarm

Place an approved message in the DLQ.

**Expected result:**

* The DLQ alarm activates.
* Operations receive notification.
* The message remains available for investigation.

## VAL-RES-005 — Origin Error

Simulate an approved origin error in staging and confirm:

* CloudFront behavior
* Alarm generation
* Recovery behavior

## VAL-RES-006 — DNS Rollback Rehearsal

**Procedure:**

1. Record current test DNS configuration.
2. Redirect to the AWS staging endpoint.
3. Validate access.
4. Restore the previous endpoint.
5. Validate access again.

**Expected result:**

* Routing changes are reversible.
* Restoration completes within the approved RTO.

---

# 24. Backup and Recovery Validation

## VAL-BACKUP-001 — S3 Version Restoration

**Priority:** Critical

**Procedure:**

1. Select an approved test object.
2. Create a new version or delete-marker scenario.
3. Restore the prior version.

**Expected result:**

* The object is restored correctly.
* Integrity is preserved.

---

## VAL-BACKUP-002 — DynamoDB Point-in-Time Recovery

**Priority:** Critical where PITR is required

**Procedure:**

1. Use an approved test table or approved recovery process.
2. Restore to a selected point in time.
3. Compare restored records.

**Expected result:**

* Required records are restored.
* Restoration time meets the approved RTO.

---

## VAL-BACKUP-003 — Infrastructure Redeployment

**Priority:** Critical

**Procedure:**

1. Use approved Infrastructure as Code in a non-production environment.
2. Deploy the required resources.
3. Validate configuration.

**Expected result:**

* Infrastructure can be reproduced.
* Security controls are included.
* Configuration drift is not required for operation.

---

## VAL-BACKUP-004 — Configuration Restoration

Validate restoration of:

* CloudFront configuration
* WAF configuration
* IAM policies
* EventBridge rules
* Step Functions definitions
* Alarm definitions
* DNS configuration

---

## VAL-BACKUP-005 — Recovery Time Objective

Measure the duration of an approved recovery exercise.

**Expected result:**

* Recovery completes within the approved RTO.

---

## VAL-BACKUP-006 — Recovery Point Objective

Compare lost or unrecoverable data against the approved RPO.

**Expected result:**

* Data loss remains within the approved RPO.

---

# 25. Monitoring and Alert Validation

## VAL-MON-001 — API Error Alarm

Generate an approved API error condition.

**Expected result:**

* The alarm activates.
* Notification reaches the Operations Lead.
* Recovery is recorded.

## VAL-MON-002 — Lambda Error Alarm

Trigger an approved Lambda failure.

## VAL-MON-003 — Lambda Throttle Alarm

Generate an approved throttling test in non-production.

## VAL-MON-004 — Step Functions Failure Alarm

Trigger a failed execution.

## VAL-MON-005 — MediaConvert Failure Alarm

Submit an invalid approved test job.

## VAL-MON-006 — MediaLive Input-Loss Alarm

Interrupt the staging live input.

## VAL-MON-007 — CloudFront Error Alarm

Generate an approved origin or request failure.

## VAL-MON-008 — WAF Alert

Trigger an approved WAF sample request.

## VAL-MON-009 — Cost Alert

Use an approved budget test or temporary low non-production threshold.

**Expected result:**

* The budget alert reaches the approved recipients.

---

# 26. Cost Validation

## 26.1 Cost categories

Review:

* MediaLive running hours
* MediaPackage usage
* MediaConvert jobs
* CloudFront requests and transfer
* S3 storage
* S3 requests
* DynamoDB requests
* Lambda invocations and duration
* API Gateway requests
* Transcribe usage
* Translate usage
* CloudWatch ingestion and retention
* KMS requests
* Data transfer

## VAL-COST-001 — Pilot Cost Review

Compare actual pilot cost with the estimate.

**Expected result:**

* Variance is explained.
* Unexpected services are investigated.
* Cost remains within the approved tolerance.

## VAL-COST-002 — Tagging Validation

Confirm that required resources have:

* Project
* Environment
* Owner
* Cost center
* Data classification

## VAL-COST-003 — Budget Alert

Confirm the budget and forecast alert configuration.

## VAL-COST-004 — Unused Resource Review

Identify:

* Idle MediaLive channels
* Temporary files
* Unused test distributions
* Unused log groups
* Unused queues
* Unused snapshots or backup copies

---

# 27. Client Compatibility Validation

Each of the seven clients must be validated.

| Client   | Authentication | API | VOD | Live | Subtitles | Protected content | Result |
| -------- | -------------- | --- | --- | ---- | --------- | ----------------- | ------ |
| Client 1 |                |     |     |      |           |                   |        |
| Client 2 |                |     |     |      |           |                   |        |
| Client 3 |                |     |     |      |           |                   |        |
| Client 4 |                |     |     |      |           |                   |        |
| Client 5 |                |     |     |      |           |                   |        |
| Client 6 |                |     |     |      |           |                   |        |
| Client 7 |                |     |     |      |           |                   |        |

For each client, test:

* Login
* Logout
* Token expiry
* Media catalogue
* VOD playback
* Live playback
* Subtitle selection
* Reconnection
* Error handling
* Protected-content access
* Network interruption where practical

---

# 28. Cutover Validation

Production cutover validation must follow the checkpoints in `RUNBOOK.md`.

## 28.1 Checkpoint 1 — Platform Readiness

Validate:

* Infrastructure deployed
* Security controls active
* Monitoring active
* No Critical defect open
* Rollback path available

## 28.2 Checkpoint 2 — Synchronization Complete

Validate:

* Media counts
* Checksums
* Metadata counts
* Object references
* Representative playback
* Incremental synchronization

## 28.3 Checkpoint 3 — Pre-Traffic Validation

Validate:

* Authentication
* API
* Live stream
* VOD workflow
* Subtitles
* CloudFront
* Security monitoring

## 28.4 Traffic-Stage Validation

At each traffic stage, validate:

* API error rates
* API latency
* Authentication success
* Playback failure rate
* CloudFront errors
* Live-stream health
* Workflow failures
* Queue depth
* DLQ depth
* Security findings

## 28.5 Full-Traffic Validation

At 100% AWS traffic, confirm:

* All clients operate normally.
* No rollback threshold is exceeded.
* No Critical alarm is active.
* Data remains consistent.
* Business acceptance is available.

---

# 29. Rollback Validation

## VAL-RB-001 — Traffic Restoration

Confirm traffic can be returned to the previous platform.

## VAL-RB-002 — DNS Restoration

Confirm previous DNS records can be restored.

## VAL-RB-003 — AWS Ingestion Pause

Confirm the approved ingestion rule can be disabled safely.

## VAL-RB-004 — Client Reconnection

Confirm clients reconnect to the previous platform.

## VAL-RB-005 — Data Reconciliation

Confirm data created during the cutover can be identified and reconciled.

## VAL-RB-006 — Evidence Preservation

Confirm logs, queues, execution histories, and security events remain available after rollback.

## VAL-RB-007 — Rollback Duration

Measure rollback time.

**Expected result:**

* Rollback completes within the approved maximum duration.

---

# 30. User Acceptance Testing

User acceptance must confirm that the platform supports required business operations.

## 30.1 UAT scenarios

* User login
* Media browsing
* VOD playback
* Live playback
* Subtitle language selection
* Protected-content access
* Error handling
* Client reconnection
* Acceptable playback quality
* Acceptable response time

## 30.2 UAT acceptance

| Scenario           | Business owner result | Notes |
| ------------------ | --------------------- | ----- |
| Authentication     |                       |       |
| VOD playback       |                       |       |
| Live playback      |                       |       |
| Subtitle support   |                       |       |
| Performance        |                       |       |
| Usability          |                       |       |
| Overall acceptance |                       |       |

---

# 31. Stabilization Validation

During the stabilization period, review daily:

* Availability
* API errors
* API latency
* Playback failures
* MediaLive health
* MediaConvert failures
* Step Functions failures
* Queue depth
* DLQ depth
* Subtitle failures
* CloudFront cache-hit ratio
* WAF events
* GuardDuty findings
* Configuration changes
* Daily AWS cost
* Support incidents

## 31.1 Stabilization exit criteria

The stabilization period is complete when:

* No unresolved Critical incident exists.
* No recurring High-severity defect remains.
* Performance meets agreed targets.
* Cost remains within approved limits.
* Media and metadata reconciliation remains valid.
* Security monitoring remains operational.
* Business and technical owners approve closure.

---

# 32. Requirements Traceability Matrix

| Requirement                 | Validation area           | Primary tests                         |
| --------------------------- | ------------------------- | ------------------------------------- |
| At least 99.9% availability | Resilience and monitoring | VAL-RES series                        |
| Secure authentication       | F1                        | VAL-F1 series                         |
| Live-stream delivery        | F2                        | VAL-F2 series                         |
| VOD processing              | F3                        | VAL-F3 series                         |
| Subtitle support            | F4                        | VAL-F4 series                         |
| Global content delivery     | F5                        | VAL-F5 series                         |
| Private S3 origins          | F5/F6                     | VAL-F5-003, VAL-F6-008                |
| Encryption                  | F6                        | VAL-F6-009 and configuration evidence |
| Audit logging               | F6                        | VAL-F6-004, VAL-F6-005                |
| Configuration monitoring    | F6                        | VAL-F6-006                            |
| Threat detection            | F6                        | VAL-F6-007                            |
| Data integrity              | Data migration            | VAL-DATA series                       |
| Recovery capability         | Backup and recovery       | VAL-BACKUP series                     |
| Rollback capability         | Rollback                  | VAL-RB series                         |
| Cost control                | Cost                      | VAL-COST series                       |

---

# 33. Test Execution Summary

| Test area              | Planned | Passed | Failed | Blocked | Not tested |
| ---------------------- | ------: | -----: | -----: | ------: | ---------: |
| F1 Authentication/API  |         |        |        |         |            |
| F2 Live streaming      |         |        |        |         |            |
| F3 VOD processing      |         |        |        |         |            |
| F4 Subtitles           |         |        |        |         |            |
| F5 Content delivery    |         |        |        |         |            |
| F6 Security/monitoring |         |        |        |         |            |
| Data migration         |         |        |        |         |            |
| Performance            |         |        |        |         |            |
| Resilience             |         |        |        |         |            |
| Backup/recovery        |         |        |        |         |            |
| Cost                   |         |        |        |         |            |
| Client compatibility   |         |        |        |         |            |
| Cutover/rollback       |         |        |        |         |            |

---

# 34. Open Defect Summary

| Defect ID | Severity | Description | Owner | Status | Cutover impact |
| --------- | -------- | ----------- | ----- | ------ | -------------- |
|           |          |             |       |        |                |

---

# 35. Validation Risks

| Risk                                     | Impact                         | Mitigation                                                 |
| ---------------------------------------- | ------------------------------ | ---------------------------------------------------------- |
| Production-like load cannot be generated | Incomplete capacity evidence   | Use controlled load simulation and conservative thresholds |
| Client availability is limited           | Compatibility gaps             | Schedule client tests early                                |
| Live-stream failure testing is risky     | Incomplete resilience evidence | Perform failure tests in staging                           |
| Test data is not representative          | Invalid conclusions            | Include multiple formats, sizes, and languages             |
| WAF false positives                      | Valid requests blocked         | Test count mode before block mode                          |
| Cost test duration is short              | Inaccurate forecast            | Use pilot data and AWS cost estimates                      |
| Subtitle accuracy is subjective          | Disputed acceptance            | Define language-owner acceptance criteria                  |
| RTO or RPO is undefined                  | Recovery cannot be accepted    | Finalize before recovery testing                           |
| Evidence is incomplete                   | Audit and approval delay       | Use mandatory evidence checklist                           |

---

# 36. Validation Report

At the end of each validation cycle, the Test Lead must produce a report containing:

1. Validation scope
2. Environment
3. Execution dates
4. Test summary
5. Failed tests
6. Open defects
7. Security findings
8. Performance results
9. Data reconciliation results
10. Recovery results
11. Cost results
12. Exceptions
13. Residual risks
14. Recommendation
15. Approvals

The recommendation must be one of:

```text
APPROVED FOR CUTOVER
APPROVED WITH CONDITIONS
NOT APPROVED FOR CUTOVER
```

---

# 37. Final Acceptance Criteria

The AWS media platform is considered validated when:

* All Critical tests pass.
* All mandatory security controls pass.
* No Critical defect remains.
* High-severity defects are resolved or formally accepted.
* All required clients pass compatibility tests.
* VOD processing works from ingest to playback.
* Live-streaming works from encoder to playback.
* Required subtitles are available and synchronized.
* Direct private-origin access is denied.
* Media checksums and object counts reconcile.
* Metadata records reconcile.
* Monitoring and alerts operate correctly.
* Backup and recovery tests pass.
* Rollback testing passes.
* Performance targets are achieved.
* Cost remains within approved thresholds.
* Business acceptance is recorded.

---

# 38. Final Approval

| Role             | Name | Decision | Date | Signature or record |
| ---------------- | ---- | -------- | ---- | ------------------- |
| Test Lead        |      |          |      |                     |
| Migration Lead   |      |          |      |                     |
| Cloud Engineer   |      |          |      |                     |
| Application Lead |      |          |      |                     |
| Media Engineer   |      |          |      |                     |
| Data Lead        |      |          |      |                     |
| Security Lead    |      |          |      |                     |
| Operations Lead  |      |          |      |                     |
| Business Owner   |      |          |      |                     |
