# EKS Control Plane Logging

## Overview

Amazon EKS control plane logging provides audit and diagnostic logs from the EKS control plane to **CloudWatch Logs**. This blueprint supports enabling and configuring all five types of control plane logs:

| Log Type | Description | Use Case |
|----------|-------------|----------|
| **api** | API server logs | API requests, responses, and errors |
| **audit** | Kubernetes audit logs | Who did what, when, and from where (compliance) |
| **authenticator** | Authentication logs | IAM authentication attempts and results |
| **controllerManager** | Controller manager logs | Core Kubernetes controllers (deployments, replicasets, etc.) |
| **scheduler** | Scheduler logs | Pod scheduling decisions and failures |

## Why Enable Control Plane Logging?

### Security & Compliance ✅
- **Audit trail** - Track all API calls and authentication attempts
- **Compliance requirements** - SOC 2, PCI-DSS, HIPAA, etc.
- **Security investigations** - Identify unauthorized access attempts
- **Change tracking** - Monitor who modified cluster resources

### Troubleshooting & Operations 🔧
- **Debug API issues** - Investigate failed API requests
- **Scheduler problems** - Understand why pods aren't scheduling
- **Authentication failures** - Debug IAM/RBAC issues
- **Performance analysis** - Identify slow or problematic API calls

### Cost Considerations 💰
- **CloudWatch ingestion** - ~$0.50/GB ingested
- **CloudWatch storage** - ~$0.03/GB/month
- **Typical costs** - $20-$100/month for most clusters
- **Optimization** - Use INFREQUENT_ACCESS log class for audit/compliance logs

## Configuration

### Basic Configuration (Recommended for Production)

Enable the most important log types in `terraform.tfvars`:

```hcl
# Enable control plane logging
enable_cluster_control_plane_logging = true

# Enable recommended log types for production
cluster_enabled_log_types = ["api", "audit", "authenticator"]

# Retain logs for 90 days
cloudwatch_log_group_retention_in_days = 90

# Use standard log class
cloudwatch_log_group_class = "STANDARD"
```

### All Log Types (Security & Compliance)

Enable all five log types for maximum visibility:

```hcl
enable_cluster_control_plane_logging = true

# Enable ALL log types
cluster_enabled_log_types = [
  "api",
  "audit",
  "authenticator",
  "controllerManager",
  "scheduler"
]

# Longer retention for compliance
cloudwatch_log_group_retention_in_days = 365

# Optional: Encrypt logs with KMS
cloudwatch_log_group_kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
```

### Minimal Configuration (Cost-Optimized)

Enable only audit and authenticator logs:

```hcl
enable_cluster_control_plane_logging = true

# Minimal logging for cost savings
cluster_enabled_log_types = ["audit", "authenticator"]

# Shorter retention
cloudwatch_log_group_retention_in_days = 30

# Use infrequent access for lower costs
cloudwatch_log_group_class = "INFREQUENT_ACCESS"
```

### Disable Logging (Development/Testing)

Disable control plane logging to save costs:

```hcl
enable_cluster_control_plane_logging = false
```

## Log Types Deep Dive

### 1. API Server Logs (`api`)

**What it logs:**
- All API server requests and responses
- Request methods (GET, POST, PUT, DELETE, PATCH)
- Response status codes (200, 404, 500, etc.)
- Request latency and performance metrics

**When to enable:**
- Troubleshooting API errors (403, 404, 500)
- Debugging kubectl or application API issues
- Performance analysis and optimization
- Understanding cluster API usage patterns

**Example use cases:**
```bash
# Find all 403 Forbidden errors
kubectl logs -l component=kube-apiserver | grep "403"

# Find slow API requests (>1s)
kubectl logs -l component=kube-apiserver | grep "latency" | grep "[1-9][0-9][0-9][0-9]ms"
```

**Volume:** High (10-50 GB/month for active clusters)

### 2. Audit Logs (`audit`)

**What it logs:**
- **Who**: IAM principal or Kubernetes user
- **What**: Action performed (create, update, delete, get, list)
- **When**: Timestamp of the action
- **Where**: Source IP address
- **Which**: Resource affected (pod, deployment, service, etc.)

**When to enable:**
- Compliance requirements (mandatory for most compliance frameworks)
- Security auditing and forensics
- Change management and tracking
- Identifying unauthorized access

**Example queries:**
```bash
# Find who deleted a pod
grep "delete.*pods" /aws/eks/my-cluster/cluster

# Track all actions by a specific user
grep "user.username=john.doe" /aws/eks/my-cluster/cluster

# Find all failed authentication attempts
grep "authentication failed" /aws/eks/my-cluster/cluster
```

**Volume:** Medium-High (5-30 GB/month depending on cluster activity)

**Compliance:** ⚠️ **REQUIRED** for SOC 2, PCI-DSS, HIPAA, ISO 27001

### 3. Authenticator Logs (`authenticator`)

**What it logs:**
- IAM authentication attempts (aws-iam-authenticator)
- Success/failure of authentication
- IAM principal details (users, roles, assumed roles)
- Token validation errors

**When to enable:**
- Debugging IAM authentication issues
- Tracking who accessed the cluster
- Identifying unauthorized access attempts
- RBAC troubleshooting

**Example use cases:**
```bash
# Find failed authentication attempts
grep "authentication failed" /aws/eks/my-cluster/cluster

# Track specific IAM role access
grep "arn:aws:iam::123456789012:role/MyRole" /aws/eks/my-cluster/cluster
```

**Volume:** Low-Medium (1-5 GB/month)

### 4. Controller Manager Logs (`controllerManager`)

**What it logs:**
- Deployment controller operations
- ReplicaSet scaling events
- StatefulSet management
- DaemonSet operations
- Service and endpoint updates

**When to enable:**
- Debugging deployment issues (pods not scaling, replicas not updating)
- Understanding controller behavior
- Troubleshooting StatefulSet problems
- Deep troubleshooting of core Kubernetes components

**Example use cases:**
```bash
# Debug why deployment isn't scaling
grep "deployment-controller" /aws/eks/my-cluster/cluster | grep "my-deployment"

# Find replicaset controller errors
grep "replicaset-controller" /aws/eks/my-cluster/cluster | grep "error"
```

**Volume:** Medium (3-15 GB/month)

### 5. Scheduler Logs (`scheduler`)

**What it logs:**
- Pod scheduling decisions
- Node affinity/anti-affinity evaluations
- Resource availability checks
- Scheduling failures and reasons

**When to enable:**
- Pods stuck in Pending state
- Understanding why pods aren't scheduling
- Node affinity/anti-affinity debugging
- Resource constraint troubleshooting

**Example use cases:**
```bash
# Find why pod isn't scheduling
grep "my-pod-name" /aws/eks/my-cluster/cluster | grep "scheduler"

# Find all pods that failed to schedule due to insufficient CPU
grep "insufficient cpu" /aws/eks/my-cluster/cluster
```

**Volume:** Low-Medium (2-10 GB/month)

## Variables Reference

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `enable_cluster_control_plane_logging` | bool | `true` | Enable/disable control plane logging |
| `cluster_enabled_log_types` | list(string) | `["api", "audit", "authenticator"]` | Log types to enable |
| `cloudwatch_log_group_retention_in_days` | number | `90` | Days to retain logs |
| `cloudwatch_log_group_kms_key_id` | string | `""` | KMS key for log encryption (optional) |
| `cloudwatch_log_group_class` | string | `"STANDARD"` | Log class (STANDARD or INFREQUENT_ACCESS) |

### Valid Log Types

```hcl
cluster_enabled_log_types = [
  "api",                 # API server logs
  "audit",              # Audit logs
  "authenticator",      # IAM authentication logs
  "controllerManager",  # Controller manager logs
  "scheduler"           # Scheduler logs
]
```

### Valid Retention Periods (days)

```
1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 
1096, 1827, 2192, 2557, 2922, 3288, 3653
```

## Log Class: STANDARD vs INFREQUENT_ACCESS

### STANDARD (Default)
- **Storage cost:** $0.03/GB/month
- **Ingestion cost:** $0.50/GB
- **Query performance:** Fast
- **Use when:** Logs are frequently queried (daily/weekly)

### INFREQUENT_ACCESS
- **Storage cost:** $0.015/GB/month (50% cheaper)
- **Ingestion cost:** $0.50/GB (same)
- **Query performance:** Slightly slower
- **Use when:** Logs rarely queried (compliance/audit archives)

**Cost comparison for 100GB/month:**
- STANDARD: $53/month ($50 ingestion + $3 storage)
- INFREQUENT_ACCESS: $51.50/month ($50 ingestion + $1.50 storage)

💡 **Tip:** Use INFREQUENT_ACCESS if you query logs less than once per month.

## Outputs

The blueprint provides outputs for CloudWatch Logs:

```bash
# Get CloudWatch Log Group name
terraform output cloudwatch_log_group_name
# Output: /aws/eks/my-eks-automode-cluster/cluster

# Get CloudWatch Log Group ARN
terraform output cloudwatch_log_group_arn

# Get enabled log types
terraform output enabled_cluster_log_types
# Output: ["api", "audit", "authenticator"]
```

## Querying Logs

### Using AWS Console

1. Navigate to **CloudWatch → Log groups**
2. Find log group: `/aws/eks/<cluster-name>/cluster`
3. Click **Log streams** to see individual log streams
4. Use **CloudWatch Logs Insights** for advanced queries

### Using AWS CLI

```bash
# List log streams
aws logs describe-log-streams \
  --log-group-name /aws/eks/my-cluster/cluster \
  --order-by LastEventTime \
  --descending

# Tail logs in real-time
aws logs tail /aws/eks/my-cluster/cluster --follow

# Get logs from the last hour
aws logs tail /aws/eks/my-cluster/cluster --since 1h

# Filter logs
aws logs tail /aws/eks/my-cluster/cluster --filter-pattern "ERROR"
```

### Using CloudWatch Logs Insights

Example queries for common use cases:

#### Find Authentication Failures
```
fields @timestamp, @message
| filter @message like /authentication failed/
| sort @timestamp desc
| limit 100
```

#### Top 10 API Endpoints
```
fields @timestamp, @message
| parse @message /\"(?<method>\w+) (?<endpoint>\/[^ ]*)/
| stats count() by endpoint
| sort count desc
| limit 10
```

#### Find Slow API Requests (>1s)
```
fields @timestamp, @message
| filter @message like /latency/
| parse @message /latency:(?<latency>\d+)/
| filter latency > 1000
| sort latency desc
```

#### Audit: Who Deleted Resources
```
fields @timestamp, @message
| filter @message like /delete/
| parse @message /user.username=(?<user>[^ ]*)/
| parse @message /objectRef.resource=(?<resource>[^ ]*)/
| display @timestamp, user, resource
```

#### Failed Pod Scheduling
```
fields @timestamp, @message
| filter @message like /Failed to schedule/
| parse @message /pod=(?<pod>[^ ]*)/
| stats count() by pod
```

## Cost Estimation

### Typical Monthly Costs (by cluster size)

| Cluster Size | Activity | Log Volume | Monthly Cost* |
|--------------|----------|------------|---------------|
| Small (1-10 nodes) | Low | 10-20 GB | $5-$10 |
| Medium (10-50 nodes) | Medium | 30-60 GB | $15-$30 |
| Large (50+ nodes) | High | 100+ GB | $50-$100+ |

*Based on enabling api, audit, authenticator logs with 90-day retention

### Cost Breakdown

```
Ingestion: $0.50/GB
Storage (STANDARD): $0.03/GB/month
Storage (INFREQUENT_ACCESS): $0.015/GB/month

Example: 50GB/month, 90-day retention, STANDARD class
- Ingestion: 50 GB × $0.50 = $25/month
- Storage: 50 GB × $0.03 = $1.50/month
- Total: ~$26.50/month
```

### Cost Optimization Tips

1. **Selective logging** - Only enable log types you actually use
   ```hcl
   # Instead of all logs
   cluster_enabled_log_types = ["audit", "authenticator"]
   ```

2. **Shorter retention** - Reduce retention for non-compliance clusters
   ```hcl
   cloudwatch_log_group_retention_in_days = 30  # Instead of 90
   ```

3. **Use INFREQUENT_ACCESS** - For compliance/audit logs rarely queried
   ```hcl
   cloudwatch_log_group_class = "INFREQUENT_ACCESS"
   ```

4. **Export to S3** - Archive old logs to S3 for long-term storage
   ```bash
   aws logs create-export-task \
     --log-group-name /aws/eks/my-cluster/cluster \
     --from 1609459200000 \
     --to 1612137600000 \
     --destination s3-bucket-name
   ```

5. **Metric filters & alarms** - Create alarms instead of manual log review
   ```bash
   aws logs put-metric-filter \
     --log-group-name /aws/eks/my-cluster/cluster \
     --filter-name AuthFailures \
     --filter-pattern "authentication failed" \
     --metric-transformations \
       metricName=AuthFailures,metricNamespace=EKS,metricValue=1
   ```

## Security Best Practices

### ✅ DO

1. **Enable audit logs** - Required for most compliance frameworks
   ```hcl
   cluster_enabled_log_types = ["audit", "authenticator", "api"]
   ```

2. **Encrypt logs with KMS** - Protect sensitive data
   ```hcl
   cloudwatch_log_group_kms_key_id = aws_kms_key.cloudwatch.arn
   ```

3. **Set appropriate retention** - Balance compliance and cost
   ```hcl
   # Production/Compliance
   cloudwatch_log_group_retention_in_days = 365
   
   # Development
   cloudwatch_log_group_retention_in_days = 30
   ```

4. **Restrict log access** - Use IAM policies to control who can view logs
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [{
       "Effect": "Allow",
       "Action": [
         "logs:FilterLogEvents",
         "logs:GetLogEvents"
       ],
       "Resource": "arn:aws:logs:*:*:log-group:/aws/eks/*"
     }]
   }
   ```

5. **Set up alerts** - Monitor for security events
   - Failed authentication attempts
   - Unauthorized API calls
   - Resource deletions
   - Policy violations

### ❌ DON'T

1. **Don't disable audit logs in production** - Required for compliance
2. **Don't use overly long retention** - Increases costs unnecessarily
3. **Don't grant unrestricted log access** - Logs contain sensitive data
4. **Don't ignore log analysis** - Logs are only useful if reviewed

## Compliance Requirements

| Framework | Required Logs | Minimum Retention |
|-----------|---------------|-------------------|
| **SOC 2** | audit, authenticator | 365 days |
| **PCI-DSS** | audit, authenticator, api | 365 days |
| **HIPAA** | audit, authenticator | 2555 days (7 years) |
| **ISO 27001** | audit, authenticator | 365 days |
| **FedRAMP** | audit, authenticator, api | 2555 days (7 years) |
| **GDPR** | audit (for access tracking) | Varies by policy |

⚠️ **Important:** Always verify compliance requirements with your security/compliance team.

## Monitoring & Alerts

### Create CloudWatch Alarms

#### Alert on Authentication Failures

```bash
# Create metric filter
aws logs put-metric-filter \
  --log-group-name /aws/eks/my-cluster/cluster \
  --filter-name EKS-AuthFailures \
  --filter-pattern "authentication failed" \
  --metric-transformations \
    metricName=AuthenticationFailures,metricNamespace=EKS/Security,metricValue=1

# Create alarm
aws cloudwatch put-metric-alarm \
  --alarm-name eks-auth-failures \
  --alarm-description "Alert on EKS authentication failures" \
  --metric-name AuthenticationFailures \
  --namespace EKS/Security \
  --statistic Sum \
  --period 300 \
  --threshold 5 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 1
```

#### Alert on Unauthorized API Calls (403)

```bash
aws logs put-metric-filter \
  --log-group-name /aws/eks/my-cluster/cluster \
  --filter-name EKS-UnauthorizedAPICalls \
  --filter-pattern '[...] "403"' \
  --metric-transformations \
    metricName=UnauthorizedAPICalls,metricNamespace=EKS/Security,metricValue=1
```

## Troubleshooting

### Logs Not Appearing

**Problem:** Control plane logs not showing up in CloudWatch.

**Solution:**
1. Verify logging is enabled:
   ```bash
   aws eks describe-cluster --name my-cluster \
     --query 'cluster.logging.clusterLogging[0].enabled'
   ```

2. Check enabled log types:
   ```bash
   aws eks describe-cluster --name my-cluster \
     --query 'cluster.logging.clusterLogging[0].types'
   ```

3. Verify CloudWatch Log Group exists:
   ```bash
   aws logs describe-log-groups \
     --log-group-name-prefix /aws/eks/my-cluster
   ```

4. Check IAM permissions - EKS needs permissions to write to CloudWatch

### High CloudWatch Costs

**Problem:** CloudWatch Logs costs are higher than expected.

**Solution:**
1. **Check log volume:**
   ```bash
   aws logs describe-log-groups \
     --log-group-name-prefix /aws/eks/ \
     --query 'logGroups[*].[logGroupName,storedBytes]' \
     --output table
   ```

2. **Reduce enabled log types:**
   ```hcl
   # From all logs
   cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
   
   # To minimal
   cluster_enabled_log_types = ["audit", "authenticator"]
   ```

3. **Reduce retention:**
   ```hcl
   cloudwatch_log_group_retention_in_days = 30  # Instead of 90 or 365
   ```

4. **Use INFREQUENT_ACCESS:**
   ```hcl
   cloudwatch_log_group_class = "INFREQUENT_ACCESS"
   ```

### Cannot Query Old Logs

**Problem:** Old logs are no longer available.

**Solution:**
- Logs are automatically deleted after the retention period
- Check your retention setting:
  ```bash
  aws logs describe-log-groups \
    --log-group-name /aws/eks/my-cluster/cluster \
    --query 'logGroups[0].retentionInDays'
  ```
- To keep logs longer, increase retention or export to S3

## Example Configurations

### Production (Security-Focused)

```hcl
# terraform.tfvars
enable_cluster_control_plane_logging = true

cluster_enabled_log_types = [
  "api",
  "audit",
  "authenticator"
]

cloudwatch_log_group_retention_in_days = 365
cloudwatch_log_group_class = "STANDARD"

# Encrypt logs with KMS
cloudwatch_log_group_kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
```

### Compliance (All Logs, Long Retention)

```hcl
enable_cluster_control_plane_logging = true

# Enable ALL log types
cluster_enabled_log_types = [
  "api",
  "audit",
  "authenticator",
  "controllerManager",
  "scheduler"
]

# 7 years for HIPAA/FedRAMP compliance
cloudwatch_log_group_retention_in_days = 2557

# Use INFREQUENT_ACCESS for cost savings
cloudwatch_log_group_class = "INFREQUENT_ACCESS"

cloudwatch_log_group_kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
```

### Development (Cost-Optimized)

```hcl
# Minimal logging for dev
enable_cluster_control_plane_logging = true

cluster_enabled_log_types = ["audit"]

cloudwatch_log_group_retention_in_days = 7
cloudwatch_log_group_class = "STANDARD"

# No KMS encryption needed for dev
cloudwatch_log_group_kms_key_id = ""
```

### Testing (Disabled)

```hcl
# No logging for temporary test clusters
enable_cluster_control_plane_logging = false
```

## Related Documentation

- [AWS EKS Control Plane Logging](https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html)
- [CloudWatch Logs Pricing](https://aws.amazon.com/cloudwatch/pricing/)
- [CloudWatch Logs Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/AnalyzingLogData.html)
- [Secrets Encryption](SECRETS_ENCRYPTION.md) - KMS encryption for secrets
- [IAM Permissions](IAM_PERMISSIONS.md) - Required IAM policies

## Summary

✅ **Enable in production** - Essential for security, compliance, and troubleshooting  
✅ **Start with recommended logs** - api, audit, authenticator  
✅ **Set appropriate retention** - 90 days for production, 365+ for compliance  
✅ **Monitor costs** - Use INFREQUENT_ACCESS for rarely-accessed logs  
✅ **Create alerts** - Don't just collect logs, act on them  
✅ **Regular review** - Periodically analyze logs for security and operational insights
