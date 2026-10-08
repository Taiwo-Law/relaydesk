# RelayDesk Operations Runbook

## Overview

This runbook documents operational procedures for the RelayDesk application deployed on AWS ECS Fargate. Commands use Windows PowerShell; run Terraform directory changes from the repository root.

AWS Region: ca-central-1

ECS Cluster: relaydesk-cluster

ECS Service: relaydesk-service

Terraform Directory: terraform/

## Operational Procedures

1. Start the ECS service

2. Verify deployment and application health

3. Inspect CloudWatch logs and metrics

4. Respond to monitoring alerts

5. Troubleshoot failed deployments

6. Stop ECS resources to minimize AWS costs

## 1. Start the ECS Service

### Purpose

Start the RelayDesk application on AWS ECS Fargate for development, testing, or troubleshooting.

### Prerequisites

- AWS CLI installed and authenticated

- Terraform installed

- Access to the RelayDesk AWS environment

- Local Terraform configuration and state available

### Step 1: Navigate to Terraform

```powershell
# Run from the cloned RelayDesk repository root
cd .\terraform
```

### Step 2: Review the Terraform Plan

```powershell
terraform plan -var="ecs_desired_count=1"
```

Expected change when the service is stopped:

```text
desired_count = 0 -> 1
```

### Step 3: Start the ECS Service

```powershell
terraform apply -var="ecs_desired_count=1"
```

Review the changes and enter `yes` to approve.

### Step 4: Wait for ECS Stability

```powershell
aws ecs wait services-stable `
  --cluster relaydesk-cluster `
  --services relaydesk-service `
  --region ca-central-1
```

The command completes successfully when ECS reaches a stable state.

### Step 5: Verify Service Status

```powershell
aws ecs describe-services `
  --cluster relaydesk-cluster `
  --services relaydesk-service `
  --region ca-central-1 `
  --query "services[0].{Desired:desiredCount,Running:runningCount,Pending:pendingCount}" `
  --output json
```

Expected output:

```json
{
  "Desired": 1,
  "Running": 1,
  "Pending": 0
}
```

### Cost Considerations

Running an ECS Fargate task incurs AWS compute charges. Its associated public IPv4 address also incurs charges.

At the end of practice, scale the ECS service back to zero using the shutdown procedure in this runbook.

### Success Criteria

- Terraform apply completed successfully

- ECS service reached a stable state

- Desired task count is 1

- Running task count is 1

- Pending task count is 0

## 2. Verify Deployment and Application Health

### Purpose

Verify that RelayDesk is running successfully on AWS ECS Fargate, its container is healthy, and the application responds to HTTP requests.

### Prerequisites

- AWS CLI installed and authenticated

- ECS service started with one running task

- AWS region: ca-central-1

### Step 1: Verify ECS Service Status

```powershell
aws ecs describe-services `
  --cluster relaydesk-cluster `
  --services relaydesk-service `
  --region ca-central-1 `
  --query "services[0].{Desired:desiredCount,Running:runningCount,Pending:pendingCount}" `
  --output json
```

Expected result:

```json
{
  "Desired": 1,
  "Running": 1,
  "Pending": 0
}
```

### Step 2: Retrieve the Running ECS Task

```powershell
$TASK = aws ecs list-tasks `
  --cluster relaydesk-cluster `
  --service-name relaydesk-service `
  --desired-status RUNNING `
  --region ca-central-1 `
  --query "taskArns[0]" `
  --output text
```

Display the task ARN:

```powershell
$TASK
```

If no running task exists, investigate the ECS service before proceeding.

### Step 3: Check Container Health

```powershell
aws ecs describe-tasks `
  --cluster relaydesk-cluster `
  --tasks $TASK `
  --region ca-central-1 `
  --query "tasks[0].containers[].{Name:name,Status:lastStatus,Health:healthStatus}" `
  --output json
```

Expected result:

```json
[
  {
    "Name": "relaydesk",
    "Status": "RUNNING",
    "Health": "HEALTHY"
  }
]
```

A running container is not necessarily healthy. The container health check confirms that RelayDesk responds to its internal `/health` endpoint.

### Step 4: Retrieve the ECS Task's Public IP

First, retrieve the task's network interface:

```powershell
$TASK_DETAILS = aws ecs describe-tasks `
  --cluster relaydesk-cluster `
  --tasks $TASK `
  --region ca-central-1 `
  --output json | ConvertFrom-Json
$ENI_ID = ($TASK_DETAILS.tasks[0].attachments[0].details |
  Where-Object { $_.name -eq "networkInterfaceId" }).value
```

Then retrieve its public IPv4 address:

```powershell
$PUBLIC_IP = aws ec2 describe-network-interfaces `
  --network-interface-ids $ENI_ID `
  --region ca-central-1 `
  --query "NetworkInterfaces[0].Association.PublicIp" `
  --output text
```

Display the address:

```powershell
$PUBLIC_IP
```

Note: The public IP may change when the ECS task is stopped, replaced, or redeployed.

### Step 5: Verify the Live Health Endpoint

```powershell
Invoke-RestMethod `
  -Uri "http://${PUBLIC_IP}:5000/health" `
  -TimeoutSec 15
```

Expected response:

```json
{
  "status": "healthy"
}
```

### Step 6: Verify the Application Endpoint

```powershell
Invoke-RestMethod `
  -Uri "http://${PUBLIC_IP}:5000/" `
  -TimeoutSec 15
```

Expected application response:

```json
{
  "service": "RelayDesk",
  "status": "running"
}
```

### Troubleshooting

If the checks fail:

1. Confirm ECS desired and running task counts.

2. Check whether the container health status is HEALTHY.

3. Verify that the task has a public IPv4 address.

4. Verify that the ECS security group allows inbound TCP port 5000.

5. Inspect CloudWatch application logs.

6. Check ECS service events for task startup or deployment failures.

The current portfolio environment exposes HTTP on port 5000 directly through the Fargate task's public IP. It does not yet have an Application Load Balancer or HTTPS termination.

### Success Criteria

- ECS service is stable.

- Desired task count matches running task count.

- Container health is HEALTHY.

- `/health` returns `healthy`.

- `/` returns the RelayDesk application status.

## 3. Investigate CloudWatch Logs and Metrics

### Purpose

Investigate RelayDesk application behavior, review container logs, monitor resource utilization, and check CloudWatch alarm states.

### Monitoring Configuration

- AWS Region: ca-central-1

- ECS Cluster: relaydesk-cluster

- ECS Service: relaydesk-service

- CloudWatch Log Group: /ecs/relaydesk

- Log Retention: 7 days

- CPU Alarm: relaydesk-ecs-cpu-high

- Memory Alarm: relaydesk-ecs-memory-high

### Step 1: View Recent Application Logs

Run the following command:

```powershell
aws logs tail /ecs/relaydesk `
  --since 10m `
  --region ca-central-1
```

This displays log events from the last 10 minutes.

The logs can help identify:

- Gunicorn startup or shutdown errors

- Application exceptions

- Container startup problems

- Unexpected application behavior

To continuously monitor new log events:

```powershell
aws logs tail /ecs/relaydesk `
  --follow `
  --region ca-central-1
```

Press Ctrl+C to stop following the logs.

### Step 2: Identify Recent Log Streams

Each ECS task can produce its own CloudWatch log stream.

```powershell
aws logs describe-log-streams `
  --log-group-name /ecs/relaydesk `
  --order-by LastEventTime `
  --descending `
  --limit 5 `
  --region ca-central-1 `
  --query "logStreams[].{Name:logStreamName,LastEvent:lastEventTimestamp}" `
  --output table
```

This helps identify recent container log streams when investigating task replacements or failed deployments.

### Step 3: Define a Monitoring Time Window

Use PowerShell to define the last hour:

```powershell
$EndTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$StartTime = (Get-Date).ToUniversalTime().AddHours(-1).ToString("yyyy-MM-ddTHH:mm:ssZ")
```

These variables will be used for CloudWatch metric queries.

### Step 4: Check ECS CPU Utilization

```powershell
aws cloudwatch get-metric-statistics `
  --namespace AWS/ECS `
  --metric-name CPUUtilization `
  --dimensions Name=ClusterName,Value=relaydesk-cluster Name=ServiceName,Value=relaydesk-service `
  --start-time $StartTime `
  --end-time $EndTime `
  --period 300 `
  --statistics Average Maximum `
  --region ca-central-1 `
  --output table
```

Interpretation:

- Average: Mean CPU utilization during each five-minute period.

- Maximum: Highest reported CPU utilization during the period.

- Sustained high CPU utilization may indicate increased application workload or insufficient compute capacity.

RelayDesk's CPU alarm is configured to trigger when average CPU utilization exceeds 70% for five consecutive one-minute periods.

### Step 5: Check ECS Memory Utilization

```powershell
aws cloudwatch get-metric-statistics `
  --namespace AWS/ECS `
  --metric-name MemoryUtilization `
  --dimensions Name=ClusterName,Value=relaydesk-cluster Name=ServiceName,Value=relaydesk-service `
  --start-time $StartTime `
  --end-time $EndTime `
  --period 300 `
  --statistics Average Maximum `
  --region ca-central-1 `
  --output table
```

Interpretation:

- Average: Mean memory utilization during each five-minute period.

- Maximum: Highest reported memory utilization during the period.

- Sustained high memory usage may indicate memory pressure, increased workload, or application memory problems.

RelayDesk's memory alarm is configured to trigger when average memory utilization exceeds 80% for five consecutive one-minute periods.

### Step 6: Check CloudWatch Alarm States

```powershell
aws cloudwatch describe-alarms `
  --alarm-names relaydesk-ecs-cpu-high relaydesk-ecs-memory-high `
  --region ca-central-1 `
  --query "MetricAlarms[].{Name:AlarmName,State:StateValue,Reason:StateReason}" `
  --output table
```

Possible alarm states:

| State | Meaning |
|-------|---------|
| OK | Alarm condition is not currently met |
| ALARM | Alarm threshold condition has been met |
| INSUFFICIENT_DATA | CloudWatch has insufficient data to evaluate the alarm |

The CPU and memory alarms are configured to send notifications through Amazon SNS when entering ALARM or returning to OK.

### Step 7: Investigate Abnormal Metrics

When CPU or memory utilization becomes unusually high:

1. Check CloudWatch alarm states.
2. Review application logs around the alarm timestamp.
3. Confirm ECS task and container health.
4. Investigate recent deployments or configuration changes.
5. Compare average and maximum utilization over time.
6. Document findings and corrective actions.

### Important Notes

- CloudWatch ECS metrics may not have recent data when the service is scaled to zero.
- Historical metrics can still be queried within CloudWatch's retention periods.
- Container logs remain available according to the seven-day log retention period.
- CloudWatch alarms and SNS remain provisioned while ECS tasks are stopped.

### Success Criteria

- Application logs and log streams can be retrieved.
- ECS CPU and memory metrics can be queried and interpreted.
- CloudWatch alarm states can be inspected.
- Observations support incident investigation and troubleshooting.

## 4. Respond to CloudWatch Alarms and SNS Notifications

### Purpose

Investigate CloudWatch CPU and memory alerts, identify possible causes, verify service recovery, and document incidents affecting RelayDesk.

### Monitoring Configuration

- AWS Region: ca-central-1

- ECS Cluster: relaydesk-cluster

- ECS Service: relaydesk-service

- CloudWatch Log Group: /ecs/relaydesk

- CPU Alarm: relaydesk-ecs-cpu-high

- Memory Alarm: relaydesk-ecs-memory-high

- SNS Topic: relaydesk-alerts

### Step 1: Identify the Alert

RelayDesk uses CloudWatch alarms to monitor ECS CPU and memory utilization.

| Alarm | Threshold | Evaluation |

|-------|-----------|------------|

| CPU | Above 70% | 5 consecutive one-minute periods |

| Memory | Above 80% | 5 consecutive one-minute periods |

CloudWatch publishes alarm and recovery notifications to Amazon SNS, which delivers email notifications to the confirmed subscriber.

When an alert arrives, record:

- Alarm name

- Timestamp

- Current alarm state

- Reason for the state change

### Step 2: Check Alarm States

```powershell
aws cloudwatch describe-alarms `
  --alarm-names relaydesk-ecs-cpu-high relaydesk-ecs-memory-high `
  --region ca-central-1 `
  --query "MetricAlarms[].{Name:AlarmName,State:StateValue,Reason:StateReason}" `
  --output table
```

Possible states:

| State | Meaning |

|-------|---------|

| OK | Configured alarm condition is not currently met |

| ALARM | Configured alarm threshold condition has been met |

| INSUFFICIENT_DATA | CloudWatch does not have sufficient data to evaluate the alarm |

An ALARM state indicates that the configured condition has been met. It does not automatically identify the underlying problem.

### Step 3: Review Alarm History

Select the alarm to investigate:

```powershell
$ALARM_NAME = "relaydesk-ecs-cpu-high"
```

For a memory alarm, use:

```powershell
$ALARM_NAME = "relaydesk-ecs-memory-high"
```

Retrieve the alarm's state-change history:

```powershell
aws cloudwatch describe-alarm-history `
  --alarm-name $ALARM_NAME `
  --history-item-type StateUpdate `
  --region ca-central-1 `
  --query "AlarmHistoryItems[].{Time:Timestamp,Summary:HistorySummary}" `
  --output table
```

Review when the alarm entered ALARM and whether it subsequently returned to OK.

Compare the timestamps with recent application activity and deployments.

### Step 4: Verify ECS Service Health

```powershell
aws ecs describe-services `
  --cluster relaydesk-cluster `
  --services relaydesk-service `
  --region ca-central-1 `
  --query "services[0].{Desired:desiredCount,Running:runningCount,Pending:pendingCount}" `
  --output json
```

Expected result when RelayDesk is intentionally running:

```json
{
  "Desired": 1,
  "Running": 1,
  "Pending": 0
}
```

If the running count is lower than the desired count, investigate task failures and ECS service events.

When RelayDesk has intentionally been scaled to zero, a count of zero is expected and does not automatically indicate an incident.

### Step 5: Investigate Application Logs

```powershell
aws logs tail /ecs/relaydesk `
  --since 30m `
  --region ca-central-1
```

Look for:

- Application exceptions

- Gunicorn errors

- Container restarts

- Unexpected application behavior

- Errors corresponding to the alarm timestamp

Use the CPU and memory metric queries documented in Procedure 3 to determine whether utilization increased suddenly or remained elevated.

### Step 6: Verify SNS Notification Configuration

If the alarm changes state but the expected email does not arrive, verify the SNS subscription.

Retrieve the AWS account ID:

```powershell
$ACCOUNT_ID = aws sts get-caller-identity `
  --query Account `
  --output text
```

Construct the SNS topic ARN:

```powershell
$TOPIC_ARN = "arn:aws:sns:ca-central-1:${ACCOUNT_ID}:relaydesk-alerts"
```

Check the subscriptions:

```powershell
aws sns list-subscriptions-by-topic `
  --topic-arn $TOPIC_ARN `
  --region ca-central-1 `
  --query "Subscriptions[].{Endpoint:Endpoint,Status:SubscriptionArn}" `
  --output table
```

A confirmed email subscription should display a subscription ARN rather than PendingConfirmation.

Verify the alarm's SNS actions:

```powershell
aws cloudwatch describe-alarms `
  --alarm-names relaydesk-ecs-cpu-high relaydesk-ecs-memory-high `
  --region ca-central-1 `
  --query "MetricAlarms[].{Name:AlarmName,AlarmActions:AlarmActions,RecoveryActions:OKActions}" `
  --output json
```

Confirm both alarm and recovery actions reference the RelayDesk SNS topic.

### Step 7: Verify Recovery

After investigating and correcting the issue:

1. Confirm the ECS service has reached a stable state.

2. Verify the container health status is HEALTHY.

3. Confirm the `/health` endpoint responds successfully.

4. Review current CPU and memory utilization.

5. Confirm the CloudWatch alarm has returned to OK, when applicable.

6. Verify that the SNS recovery notification was received.

Do not manually force an alarm into the OK state to hide an unresolved issue.

### Step 8: Document the Incident

Record relevant information for future troubleshooting.

| Field | Information |

|-------|-------------|

| Incident ID | |

| Date and time | |

| Alarm name | |

| Initial symptoms | |

| Affected service | |

| Investigation findings | |

| Root cause, if identified | |

| Corrective action | |

| Recovery verification | |

| Preventive recommendations | |

### Success Criteria

- Alarm details and history have been reviewed.

- ECS service and application health have been verified.

- Relevant CloudWatch logs and metrics have been investigated.

- SNS notification configuration has been verified if needed.

- Recovery has been confirmed.

- Significant incident findings have been documented.

## 5. Troubleshoot Failed ECS Deployments

### Purpose

Identify the cause of failed RelayDesk deployments, investigate ECS service and task failures, verify automatic rollback, and restore application health.

### Deployment Configuration

- AWS Region: `ca-central-1`

- ECS Cluster: `relaydesk-cluster`

- ECS Service: `relaydesk-service`

- Task Definition Family: `relaydesk-task`

- Container Name: `relaydesk`

- CloudWatch Log Group: `/ecs/relaydesk`

- Container Registry: GitHub Container Registry (GHCR)

RelayDesk uses GitHub Actions to automate application deployment to Amazon ECS Fargate.

The CI/CD pipeline consists of three jobs:

1. **Test:** Runs pytest, Terraform validation, Gitleaks, Trivy security scans, Docker build, and container smoke testing.

2. **Publish:** Publishes the tested Docker image to GHCR.

3. **Deploy:** Authenticates to AWS using OIDC, updates the ECS service, waits for stability, and verifies the application health endpoint.

The deployment job runs on qualifying application-changing pushes to `main` after testing and image publishing succeed.

### Step 1: Identify the Failed GitHub Actions Job

Open the RelayDesk repository:

https://github.com/Taiwo-Law/relaydesk

Navigate to **Actions → RelayDesk CI** and select the failed workflow run.

Identify the failed job:

| Failed Job | Areas to Investigate |

|---|---|

| Test | Python tests, Terraform validation, secret scanning, image vulnerabilities, container smoke tests |

| Publish to GHCR | Image artifact, registry authentication, Docker tags, image publishing |

| Deploy to AWS | AWS OIDC authentication, ECS service update, deployment stability, health verification |

Expand the failed step and review its error output.

If the deployment job fails, continue with the following ECS investigation steps.

### Step 2: Check ECS Service Status

```powershell
aws ecs describe-services `
  --cluster relaydesk-cluster `
  --services relaydesk-service `
  --region ca-central-1 `
  --query "services[0].{Desired:desiredCount,Running:runningCount,Pending:pendingCount}" `
  --output json
```

When RelayDesk is intentionally running, the expected result is:

```json
{
  "Desired": 1,
  "Running": 1,
  "Pending": 0
}
```

If the running task count is lower than the desired count, ECS may be experiencing task startup or health-check failures.

### Step 3: Inspect ECS Deployment Status

```powershell
aws ecs describe-services `
  --cluster relaydesk-cluster `
  --services relaydesk-service `
  --region ca-central-1 `
  --query "services[0].deployments[].{Status:status,Rollout:rolloutState,Reason:rolloutStateReason,TaskDefinition:taskDefinition}" `
  --output table
```

Possible deployment states include:

| State | Meaning |

|---|---|

| IN_PROGRESS | ECS is working toward the deployment's desired state |

| COMPLETED | Deployment successfully reached a steady state |

| FAILED | Deployment failed to reach a healthy steady state |

Investigate a failed deployment before attempting another deployment.

### Step 4: Review ECS Service Events

```powershell
aws ecs describe-services `
  --cluster relaydesk-cluster `
  --services relaydesk-service `
  --region ca-central-1 `
  --query "services[0].events[:10].{Time:createdAt,Message:message}" `
  --output table
```

Service events may reveal:

- Container startup failures

- Failed container health checks

- Image pull failures

- Networking or connectivity problems

- Task resource provisioning failures

- ECS deployment circuit breaker activation

Use these messages to identify the likely cause of the failure.

### Step 5: Inspect Stopped ECS Tasks

Retrieve recently stopped tasks:

```powershell
$STOPPED = aws ecs list-tasks `
  --cluster relaydesk-cluster `
  --service-name relaydesk-service `
  --desired-status STOPPED `
  --max-results 5 `
  --region ca-central-1 `
  --output json | ConvertFrom-Json
```

If stopped tasks are returned, inspect their failure reasons:

```powershell
if ($STOPPED.taskArns.Count -gt 0) {
  aws ecs describe-tasks `
    --cluster relaydesk-cluster `
    --tasks $STOPPED.taskArns `
    --region ca-central-1 `
    --query "tasks[].{StoppedReason:stoppedReason,StopCode:stopCode,Containers:containers[].{Name:name,ExitCode:exitCode,Reason:reason}}" `
    --output json
}
```

Common failure scenarios:

| Symptom | Possible Cause |

|---|---|

| Container exits immediately | Application startup error |

| Image pull failure | GHCR image, permissions, or networking issue |

| Container unhealthy | `/health` endpoint failure |

| Task fails to start | Configuration, resources, or IAM problem |

| Deployment timeout | ECS tasks cannot reach a stable state |

Recently stopped ECS tasks remain available for inspection only for a limited period, so investigate promptly.

### Step 6: Review Application Logs

```powershell
aws logs tail /ecs/relaydesk `
  --since 30m `
  --region ca-central-1
```

Look for:

- Python exceptions

- Gunicorn startup failures

- Missing application dependencies

- Container initialization errors

- Application crashes

- Unexpected runtime behavior

If the container fails before logging starts, rely on ECS service events and stopped-task reasons.

### Step 7: Verify the ECS Task Definition and Container Image

Retrieve the task definition currently configured for the service:

```powershell
$TASK_DEFINITION = aws ecs describe-services `
  --cluster relaydesk-cluster `
  --services relaydesk-service `
  --region ca-central-1 `
  --query "services[0].taskDefinition" `
  --output text
```

Inspect the container image:

```powershell
aws ecs describe-task-definition `
  --task-definition $TASK_DEFINITION `
  --region ca-central-1 `
  --query "taskDefinition.containerDefinitions[].{Name:name,Image:image}" `
  --output table
```

Verify that the specified image exists in GHCR.

**Important:** RelayDesk currently uses the mutable `latest` container tag in its ECS task definition. Although ECS deployment rollback is enabled, rollback does not necessarily guarantee restoration of previous image contents when the same mutable tag is reused.

Pinning deployments to immutable image digests or commit-specific tags is a future reliability improvement.

### Step 8: Understand Automatic Deployment Rollback

RelayDesk uses the ECS deployment circuit breaker:

```hcl
deployment_circuit_breaker {
  enable   = true
  rollback = true
}
```

When a deployment fails, ECS can attempt to restore the most recent eligible completed deployment.

This helps protect service availability when a new application version fails health checks.

However, rollback must be verified because recovery is not guaranteed.

After a failed deployment:

1. Review ECS deployment status.

2. Check whether rollback was initiated.

3. Verify ECS service stability.

4. Confirm the running container is healthy.

5. Test the application `/health` endpoint.

6. Investigate the original deployment failure.

### Step 9: Verify Application Recovery

Use **Procedure 2 — Verify Deployment and Application Health** to confirm:

- ECS desired and running counts match.

- Container status is RUNNING.

- Container health status is HEALTHY.

- The `/health` endpoint responds successfully.

- The application root endpoint responds correctly.

Do not consider the incident resolved until application functionality has been verified.

### Step 10: Document the Deployment Incident

| Field | Information |

|---|---|

| Incident date | |

| GitHub Actions run | |

| Failed job or step | |

| ECS deployment state | |

| Error message | |

| Root cause, if identified | |

| Corrective action | |

| Rollback status | |

| Recovery verification | |

| Preventive improvements | |

### Success Criteria

- The failed deployment stage has been identified.

- ECS service events and stopped-task details have been investigated.

- Relevant application logs have been reviewed.

- Image and task-definition configuration have been verified.

- Automatic rollback or other recovery action has been validated.

- Application health has been restored and confirmed.

- Incident findings have been documented.

## 6. Stop ECS Resources to Minimize AWS Costs

### Purpose

Safely stop the RelayDesk ECS Fargate application after development or practice sessions while preserving Terraform-managed infrastructure for future use.

### AWS Configuration

- AWS Region: ca-central-1

- ECS Cluster: relaydesk-cluster

- ECS Service: relaydesk-service

- Terraform Directory: terraform/

- Default ECS Desired Count: 0

- Running ECS Task Configuration: 0.25 vCPU and 512 MB memory

### Step 1: Navigate to the Terraform Directory

Open PowerShell and navigate to the Terraform configuration:

```powershell
# Run from the cloned RelayDesk repository root
cd .\terraform
```

### Step 2: Review the Current ECS Service Status

```powershell
aws ecs describe-services `
  --cluster relaydesk-cluster `
  --services relaydesk-service `
  --region ca-central-1 `
  --query "services[0].{Desired:desiredCount,Running:runningCount,Pending:pendingCount}" `
  --output json
```

When RelayDesk is running normally, the expected output is:

```json
{
  "Desired": 1,
  "Running": 1,
  "Pending": 0
}
```

If the service already reports zero desired, running, and pending tasks, the compute workload is already stopped.

### Step 3: Review the Terraform Shutdown Plan

```powershell
terraform plan -var="ecs_desired_count=0"
```

When the application is running, the expected change is:

```text
desired_count = 1 -> 0
```

Terraform should update the existing ECS service without destroying the underlying infrastructure.

Review the full plan carefully.

If Terraform proposes unexpected resource creation, replacement, or destruction, investigate before proceeding.

### Step 4: Scale the ECS Service to Zero

```powershell
terraform apply -var="ecs_desired_count=0"
```

Review the proposed changes and enter:

```text
yes
```

Terraform updates the ECS service desired task count to zero.

The ECS service remains configured, but its running Fargate task is stopped.

### Step 5: Wait for ECS Service Stability

```powershell
aws ecs wait services-stable `
  --cluster relaydesk-cluster `
  --services relaydesk-service `
  --region ca-central-1
```

Wait until the command completes successfully.

### Step 6: Verify That ECS Has Stopped

```powershell
aws ecs describe-services `
  --cluster relaydesk-cluster `
  --services relaydesk-service `
  --region ca-central-1 `
  --query "services[0].{Desired:desiredCount,Running:runningCount,Pending:pendingCount}" `
  --output json
```

Expected output:

```json
{
  "Desired": 0,
  "Running": 0,
  "Pending": 0
}
```

This confirms that the ECS service has no desired, running, or pending tasks (subject to the separate running-task check below).

### Step 7: Confirm No Running ECS Service Tasks Remain

```powershell
aws ecs list-tasks `
  --cluster relaydesk-cluster `
  --service-name relaydesk-service `
  --desired-status RUNNING `
  --region ca-central-1 `
  --output json
```

Expected output:

```json
{
  "taskArns": []
}
```

If tasks are still running, allow ECS additional time to finish stopping them and investigate if they remain running.

### Step 8: Understand Which AWS Charges Stop

Scaling ECS to zero stops the application compute workload.

| AWS Resource | After Shutdown | Billing Impact |

|---|---|---|

| ECS Fargate task | Stopped | Compute charges stop |

| Task public IPv4 address | Released after task termination | Associated public IPv4 charges stop |

| ECS cluster | Remains | No running Fargate compute charges |

| VPC and subnets | Remain | No ordinary hourly charges for these resources alone |

| Internet Gateway and route table | Remain | No ordinary hourly charges for these resources alone |

| IAM roles and policies | Remain | No standard hourly charge |

| CloudWatch log group | Remains | Stored logs may incur charges |

| CloudWatch CPU and memory alarms | Remain | Alarm charges may continue |

| SNS topic and email subscription | Remain | Usage-based charges may apply |

**Important:** Scaling ECS to zero minimizes AWS costs but does not necessarily reduce the entire AWS bill to zero.

CloudWatch alarms and stored logs may continue to incur charges independently of ECS compute.

RelayDesk does not currently use a customer-managed KMS key, NAT Gateway, Application Load Balancer, or RDS database.

### Step 9: Stop Local Development Resources

If a local RelayDesk Docker container is running, identify it:

```powershell
docker ps
```

Stop the container if necessary:

```powershell
$CONTAINER_ID = "replace-with-running-container-id"
docker stop $CONTAINER_ID
```

Replace the placeholder with the container ID displayed by `docker ps`. Skip this step if no local RelayDesk container is running.

Docker Desktop can also be closed after development work is complete.

Stopping local Docker containers does not affect AWS billing.

### Step 10: Record the Shutdown

Document the shutdown for operational tracking.

| Field | Information |

|---|---|

| Shutdown Date | |

| Shutdown Time | |

| AWS Region | ca-central-1 |

| ECS Desired Count | 0 |

| ECS Running Count | 0 |

| ECS Pending Count | 0 |

| Terraform Apply Status | |

| Outstanding Issues | |

### Restarting RelayDesk

When another development or practice session begins, navigate to the Terraform directory:

```powershell
# Run from the cloned RelayDesk repository root
cd .\terraform
```

Start the service:

```powershell
terraform apply -var="ecs_desired_count=1"
```

Review the plan and approve the change.

Wait for ECS stability:

```powershell
aws ecs wait services-stable `
  --cluster relaydesk-cluster `
  --services relaydesk-service `
  --region ca-central-1
```

Use Procedure 2 to confirm container and application health.

**Cost Warning:** Restarting the Fargate task resumes AWS compute and public IPv4 charges.

### Success Criteria

- Terraform shutdown completed successfully.

- ECS service reached a stable state.

- Desired task count is 0.

- Running task count is 0.

- Pending task count is 0.

- No running ECS service tasks remain.

- Fargate compute charges have stopped.

- Remaining billable AWS resources are understood.

- Shutdown information has been recorded.
