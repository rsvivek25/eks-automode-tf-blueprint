# AWS Application Recovery Controller (ARC) Zonal Shift

## Overview

**ARC Zonal Shift** is an AWS feature that automatically shifts traffic away from impaired Availability Zones (AZs) to healthy AZs, maintaining high availability during AZ-level impairments.

Your blueprint **now supports** ARC Zonal Shift configuration.

---

## What is ARC Zonal Shift?

### The Problem

Traditional multi-AZ deployments can still experience degraded performance when an entire Availability Zone has issues:

```
AZ-1: Healthy (33% traffic)    ✅
AZ-2: Impaired (33% traffic)   ⚠️  ← Causes latency/errors
AZ-3: Healthy (33% traffic)    ✅
```

**Result:** 33% of your traffic still goes to the impaired AZ, causing:
- ❌ Increased latency
- ❌ Connection timeouts
- ❌ Degraded user experience
- ❌ Failed health checks

### The Solution: Zonal Shift

ARC Zonal Shift automatically detects and redirects traffic:

```
AZ-1: Healthy (50% traffic)    ✅
AZ-2: Impaired (0% traffic)    ⚠️  ← Traffic shifted away
AZ-3: Healthy (50% traffic)    ✅
```

**Result:**
- ✅ Zero traffic to impaired AZ
- ✅ All traffic goes to healthy AZs
- ✅ Automatic recovery when AZ is healthy
- ✅ No manual intervention required

---

## How It Works

### Automatic Zonal Shift Process

1. **Detection**
   - AWS monitors AZ health metrics
   - Detects impairments (networking, EC2, storage issues)

2. **Shift Initiation**
   - AWS automatically initiates a zonal shift
   - Redirects traffic away from impaired AZ
   - Updates load balancer routing

3. **Traffic Redistribution**
   - Remaining AZs receive shifted traffic
   - Load balancers stop sending requests to impaired AZ
   - EKS nodes in healthy AZs handle increased load

4. **Automatic Recovery**
   - AWS monitors impaired AZ recovery
   - Automatically shifts traffic back when healthy
   - Returns to normal distribution

### Integration with EKS Auto Mode

When enabled on your EKS cluster:

```
EKS Control Plane (Multi-AZ)
   ↓
Load Balancers (ALB/NLB)
   ↓
ARC Zonal Shift monitors traffic
   ↓
Automatically shifts away from impaired AZ
   ↓
EKS Auto Mode provisions nodes in healthy AZs
```

---

## Configuration

Your blueprint provides simple enable/disable control:

### Enable Zonal Shift (Default - Recommended)

```hcl
# In terraform.tfvars
enable_zonal_shift = true
```

**What happens:**
- ✅ ARC Zonal Shift enabled for EKS cluster
- ✅ Automatic traffic shifting during AZ impairments
- ✅ No manual intervention required
- ✅ Automatic recovery when AZ is healthy

**Best for:**
- Production environments
- High-availability requirements
- Customer-facing applications
- Mission-critical workloads

---

### Disable Zonal Shift

```hcl
# In terraform.tfvars
enable_zonal_shift = false
```

**What happens:**
- ⚠️ No automatic traffic shifting
- ⚠️ Traffic continues to impaired AZ
- ⚠️ Manual intervention may be required

**Best for:**
- Development/testing environments
- When you have custom AZ failure handling
- Troubleshooting AZ-specific issues

---

## Benefits

### 1. **Improved Availability**

**Without Zonal Shift:**
```
AZ Impairment → 33% traffic affected → Degraded performance
```

**With Zonal Shift:**
```
AZ Impairment → Traffic shifted → 0% traffic affected → Normal performance
```

### 2. **Automatic Recovery**

- No need to manually update DNS or load balancers
- No need to deploy code changes
- No runbooks to execute
- No pager duty escalations

### 3. **Cost Optimization**

- Only pay for what you use
- No additional infrastructure required
- No standby resources needed
- No cross-region data transfer

### 4. **Compliance**

Helps meet SLA requirements:
- 99.99% uptime goals
- RTO (Recovery Time Objective) < 1 minute
- RPO (Recovery Point Objective) = 0 (no data loss)

---

## When Does Zonal Shift Activate?

### Automatic Triggers

ARC monitors for:

1. **Networking Issues**
   - VPC connectivity problems
   - NAT Gateway failures
   - Transit Gateway issues

2. **EC2 Capacity Issues**
   - Instance launch failures
   - Hardware degradation
   - Throttling errors

3. **Storage Issues**
   - EBS volume performance degradation
   - S3 endpoint issues

4. **Service Impairments**
   - ALB/NLB target health failures
   - EKS control plane issues

### What It Does NOT Trigger On

- ❌ Application-level errors (use auto-scaling)
- ❌ Code bugs (use proper testing)
- ❌ Database slowness (optimize queries)
- ❌ Single pod failures (use multiple replicas)

---

## Architecture Considerations

### Multi-AZ Requirements

For zonal shift to work effectively:

✅ **Required:**
- At least **2 Availability Zones** (3+ recommended)
- Subnets in each AZ properly tagged
- Load balancers deployed across AZs
- EKS Auto Mode enabled (handles node provisioning)

❌ **Won't Help If:**
- Single AZ deployment
- Application is not AZ-aware
- Database has single-AZ replica

### Capacity Planning

Ensure remaining AZs can handle shifted traffic:

```
Normal: 3 AZs × 33% capacity each = 100%
During Shift: 2 AZs × 50% capacity each = 100%

Recommendation: Size each AZ for 50% of total traffic
```

**Example:**

```hcl
# NodePool with capacity for zonal shift
apiVersion: eks.amazonaws.com/v1
kind: NodePool
metadata:
  name: amd64
spec:
  limits:
    cpu: "100"       # ← Size for 2 AZs (not 3)
    memory: "400Gi"  # ← Plan for AZ failure
```

---

## Verification

### After Deployment

```bash
# Check if zonal shift is enabled
terraform output zonal_shift_enabled

# Verify cluster configuration
aws eks describe-cluster \
  --name <cluster-name> \
  --query 'cluster.zonalShiftConfig' \
  --output json

# Expected output:
{
  "enabled": true
}
```

### Monitor Zonal Shifts

```bash
# List active zonal shifts
aws arc-zonal-shift list-zonal-shifts \
  --status ACTIVE

# Get zonal shift details
aws arc-zonal-shift get-managed-resource \
  --resource-identifier <cluster-arn>

# CloudWatch metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/ARC \
  --metric-name ZonalShiftActiveCount \
  --dimensions Name=Resource,Value=<cluster-arn> \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 3600 \
  --statistics Sum
```

---

## Cost Analysis

### Pricing

**ARC Zonal Shift:**
- ✅ **FREE** - No additional charges
- ✅ No per-shift fees
- ✅ No monitoring fees
- ✅ No data transfer fees (within region)

**You only pay for:**
- EC2 instances (same as without zonal shift)
- Load balancers (same as without zonal shift)
- Data transfer (same as without zonal shift)

**ROI:**
```
Cost of Zonal Shift:        $0/month
Cost of 1 hour outage:      $10,000+ (estimated)
Cost of manual intervention: 2-4 hours engineer time

Savings: Priceless 😊
```

---

## Best Practices

### ✅ DO

1. **Enable in Production**
   ```hcl
   enable_zonal_shift = true  # Always for prod
   ```

2. **Deploy Across 3+ AZs**
   ```hcl
   # Ensure subnets in 3 AZs
   private_subnet_tags = {
     "kubernetes.io/role/internal-elb" = "1"
   }
   ```

3. **Size for N-1 AZs**
   - If you have 3 AZs, plan capacity for 2
   - Each AZ should handle 50% of total load

4. **Test Application AZ Awareness**
   ```bash
   # Manually trigger zonal shift to test
   aws arc-zonal-shift start-zonal-shift \
     --resource-identifier <cluster-arn> \
     --away-from us-east-1a \
     --expires-in 1h \
     --comment "Testing zonal shift"
   ```

5. **Monitor Shifts**
   ```bash
   # Set up CloudWatch alarms
   aws cloudwatch put-metric-alarm \
     --alarm-name zonal-shift-active \
     --metric-name ZonalShiftActiveCount \
     --namespace AWS/ARC \
     --threshold 1 \
     --comparison-operator GreaterThanThreshold
   ```

### ❌ DON'T

1. **Don't disable in production**
   ```hcl
   enable_zonal_shift = false  # ❌ Only for dev/test
   ```

2. **Don't under-provision capacity**
   - ❌ Each AZ at 100% capacity (no room for shift)
   - ✅ Each AZ at 50-60% capacity (room for growth)

3. **Don't assume single-AZ is enough**
   - ❌ 1 AZ deployment won't benefit
   - ✅ 3+ AZ deployment recommended

4. **Don't forget application-level HA**
   - Zonal shift helps infrastructure
   - Still need multiple pod replicas
   - Still need proper health checks

---

## Testing Zonal Shift

### Manual Zonal Shift Test

```bash
# 1. Deploy test application
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: zonal-shift-test
spec:
  replicas: 6
  selector:
    matchLabels:
      app: zonal-test
  template:
    metadata:
      labels:
        app: zonal-test
    spec:
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: topology.kubernetes.io/zone
          whenUnsatisfiable: DoNotSchedule
          labelSelector:
            matchLabels:
              app: zonal-test
      containers:
        - name: nginx
          image: nginx:latest
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: zonal-test
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "external"
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "ip"
spec:
  type: LoadBalancer
  selector:
    app: zonal-test
  ports:
    - port: 80
      targetPort: 80
EOF

# 2. Check pod distribution
kubectl get pods -l app=zonal-test -o wide

# Should see pods in all 3 AZs:
# NAME                    NODE                              ZONE
# zonal-test-xxx-1        ip-10-0-1-100.ec2.internal       us-east-1a
# zonal-test-xxx-2        ip-10-0-1-101.ec2.internal       us-east-1a
# zonal-test-xxx-3        ip-10-0-2-100.ec2.internal       us-east-1b
# zonal-test-xxx-4        ip-10-0-2-101.ec2.internal       us-east-1b
# zonal-test-xxx-5        ip-10-0-3-100.ec2.internal       us-east-1c
# zonal-test-xxx-6        ip-10-0-3-101.ec2.internal       us-east-1c

# 3. Get load balancer DNS
NLB_DNS=$(kubectl get svc zonal-test -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# 4. Test normal traffic
for i in {1..100}; do curl -s http://$NLB_DNS > /dev/null && echo "Success $i"; done

# 5. Initiate manual zonal shift
aws arc-zonal-shift start-zonal-shift \
  --resource-identifier $(aws eks describe-cluster --name <cluster-name> --query 'cluster.arn' --output text) \
  --away-from us-east-1a \
  --expires-in 30m \
  --comment "Testing zonal shift behavior"

# 6. Watch traffic shift
watch -n 5 'kubectl get pods -l app=zonal-test -o wide | grep -v us-east-1a'

# 7. Verify traffic still works
for i in {1..100}; do curl -s http://$NLB_DNS > /dev/null && echo "Success $i"; done

# 8. Cancel zonal shift
aws arc-zonal-shift cancel-zonal-shift \
  --zonal-shift-id <zonal-shift-id>

# 9. Clean up
kubectl delete deployment,service zonal-shift-test
```

---

## Troubleshooting

### Issue: Zonal shift not working

**Symptoms:**
- Traffic still going to impaired AZ
- No automatic shift during AZ issues

**Check:**

```bash
# 1. Verify zonal shift is enabled
aws eks describe-cluster --name <cluster-name> \
  --query 'cluster.zonalShiftConfig.enabled'
# Should return: true

# 2. Check if resource is registered
aws arc-zonal-shift get-managed-resource \
  --resource-identifier <cluster-arn>

# 3. Verify ALB/NLB are ARC-compatible
aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[*].{Name:LoadBalancerName,Scheme:Scheme,AZs:AvailabilityZones[].ZoneName}'

# Must have 2+ AZs
```

---

### Issue: Capacity issues during shift

**Symptoms:**
- Pods pending after zonal shift
- Out of capacity errors

**Solution:**

```yaml
# Ensure NodePool has sufficient limits
apiVersion: eks.amazonaws.com/v1
kind: NodePool
metadata:
  name: amd64
spec:
  limits:
    # Size for N-1 AZs
    cpu: "100"      # Increase if needed
    memory: "400Gi" # Increase if needed
```

---

## Integration with Other AWS Services

### Works With

✅ **Application Load Balancer (ALB)**
- Automatic target group updates
- Health check integration

✅ **Network Load Balancer (NLB)**
- Automatic endpoint updates
- Cross-zone load balancing

✅ **EKS Auto Mode**
- Automatic node provisioning in healthy AZs
- Karpenter integration

✅ **CloudWatch**
- Metrics for zonal shifts
- Alarms for active shifts

### Limitations

⚠️ **Does NOT automatically shift:**
- Single-AZ resources (RDS, ElastiCache single instance)
- Static IP assignments
- Hardcoded AZ references in application

---

## Comparison with Other HA Solutions

| Solution | Scope | Automatic | Cost | Complexity |
|----------|-------|-----------|------|------------|
| **ARC Zonal Shift** | AZ-level | ✅ Yes | Free | Low |
| **Multi-Region** | Region-level | ❌ Manual | High | High |
| **Route 53 Health Checks** | DNS-level | ✅ Yes | Low | Medium |
| **Auto Scaling** | Instance-level | ✅ Yes | Moderate | Low |
| **Manual Intervention** | Any | ❌ No | Time | High |

**Recommendation:** Use zonal shift + auto-scaling + multi-region for complete HA.

---

## Summary

### What ARC Zonal Shift Provides

✅ **Automatic** traffic shifting during AZ impairments  
✅ **Zero cost** - no additional charges  
✅ **Sub-minute** recovery time  
✅ **No manual** intervention required  
✅ **Works with** ALB, NLB, EKS Auto Mode  

### Your Blueprint Configuration

```hcl
# Recommended for production
enable_zonal_shift = true
```

**Benefits:**
- Improved availability (fewer outages)
- Reduced operational burden (no manual shifts)
- Better customer experience (faster recovery)
- Cost-effective (free feature)

---

## Quick Reference

```bash
# Check if enabled
terraform output zonal_shift_enabled

# Verify cluster config
aws eks describe-cluster --name <cluster-name> \
  --query 'cluster.zonalShiftConfig'

# List active shifts
aws arc-zonal-shift list-zonal-shifts --status ACTIVE

# Manual shift (testing)
aws arc-zonal-shift start-zonal-shift \
  --resource-identifier <cluster-arn> \
  --away-from <az-name> \
  --expires-in 30m \
  --comment "Testing"

# Cancel shift
aws arc-zonal-shift cancel-zonal-shift \
  --zonal-shift-id <id>
```

---

**Recommendation:** Always enable ARC Zonal Shift for production EKS clusters! It's free and significantly improves availability. 🚀
