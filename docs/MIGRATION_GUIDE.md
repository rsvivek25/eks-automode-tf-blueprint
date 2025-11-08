# Migration Guide - Existing EKS to EKS Auto Mode

This guide helps teams migrate from existing EKS clusters (with managed node groups or self-managed nodes) to EKS Auto Mode using this blueprint.

## ⚠️ Important Considerations

### What EKS Auto Mode Changes
- **Node Management**: Shifts from manual node groups to automatic provisioning
- **Scaling**: Automatic scaling based on pod requirements (no manual ASG management)
- **Instance Selection**: Karpenter automatically selects optimal instance types
- **Lifecycle Management**: AWS manages node updates and lifecycle

### What Stays the Same
- **Control Plane**: EKS control plane remains the same
- **Networking**: VPC, subnets, and networking configuration unchanged
- **Workloads**: Existing workload manifests work as-is (with minor modifications)
- **Storage**: Existing PVCs and storage classes continue to work
- **Services**: Service and Ingress configurations remain compatible

## Migration Strategies

### Strategy 1: Blue/Green Deployment (Recommended for Production)

**Best For**: Production workloads requiring zero downtime

#### Steps:
1. **Create New Auto Mode Cluster** (Green)
   ```bash
   # In new directory
   cp terraform.tfvars.example terraform.tfvars
   # Edit with new cluster name
   terraform apply
   ```

2. **Migrate Workloads Gradually**
   ```bash
   # Export from old cluster
   kubectl get all -n <namespace> -o yaml > namespace-export.yaml
   
   # Apply to new cluster
   kubectl apply -f namespace-export.yaml
   ```

3. **Update DNS/Load Balancers**
   - Point traffic to new cluster's ingress
   - Monitor both clusters during transition
   
4. **Decommission Old Cluster**
   - After validation period (1-2 weeks)
   - Destroy old cluster resources

**Pros**: 
- Zero downtime
- Easy rollback
- Full validation before cutover

**Cons**: 
- Temporary double cost
- More complex migration

### Strategy 2: In-Place Upgrade (Development/Staging)

**Best For**: Non-production environments

**Note**: This requires cluster recreation as Auto Mode cannot be enabled on existing clusters.

#### Steps:
1. **Backup Everything**
   ```bash
   # Backup all resources
   kubectl get all --all-namespaces -o yaml > cluster-backup.yaml
   
   # Export PVs (note: data migration needed separately)
   kubectl get pv -o yaml > pvs-backup.yaml
   ```

2. **Destroy Old Cluster**
   ```bash
   terraform destroy
   ```

3. **Deploy New Auto Mode Cluster**
   ```bash
   # Update terraform configuration for Auto Mode
   terraform apply
   ```

4. **Restore Workloads**
   ```bash
   kubectl apply -f cluster-backup.yaml
   ```

**Pros**: 
- Single cluster to manage
- Lower cost during migration

**Cons**: 
- Downtime required
- Higher risk
- Data migration complexity

## Pre-Migration Checklist

### Assessment Phase
- [ ] Document current cluster configuration
- [ ] List all namespaces and workloads
- [ ] Identify stateful applications
- [ ] Document PVC/storage usage
- [ ] List custom IAM roles/policies
- [ ] Document network policies
- [ ] Identify node-specific configurations (taints, labels)
- [ ] Check add-on compatibility
- [ ] Review current instance types usage
- [ ] Document monitoring/logging setup

### Compatibility Check
- [ ] Kubernetes version compatibility (Auto Mode supports 1.29+)
- [ ] Verify workloads don't use deprecated APIs
- [ ] Check if custom CNI plugins are used (must use VPC CNI for Auto Mode)
- [ ] Verify no hard-coded node names in manifests
- [ ] Check for DaemonSets that expect specific nodes

### Data Migration Planning
- [ ] Identify persistent volumes and data
- [ ] Plan for PV migration or recreation
- [ ] Backup critical data
- [ ] Test restore procedures
- [ ] Document RTO/RPO requirements

## Workload Adaptation Guide

### Adapting Deployments for Node Pools

**Old Configuration** (Managed Node Group):
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    spec:
      nodeSelector:
        node.kubernetes.io/instance-type: t3.medium
```

**New Configuration** (Auto Mode):
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    spec:
      # Select node pool
      nodeSelector:
        NodeGroupType: amd64
      # Add toleration
      tolerations:
        - key: amd64
          effect: NoSchedule
      # Let Karpenter choose instance type
      # based on resource requests
      containers:
        - name: my-app
          resources:
            requests:
              cpu: "500m"
              memory: "512Mi"
```

### Cluster Autoscaler to Karpenter

**Remove** Cluster Autoscaler deployment if present:
```bash
kubectl delete deployment cluster-autoscaler -n kube-system
```

**No replacement needed** - Karpenter is built into EKS Auto Mode.

### Storage Class Migration

**Old** storage class might be:
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp2
provisioner: kubernetes.io/aws-ebs
```

**New** Auto Mode storage class (already included in blueprint):
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: auto-ebs-sc
provisioner: ebs.csi.eks.amazonaws.com
```

**Migration Steps**:
1. Update PVC definitions to use new storage class
2. For existing PVCs, data migration may be required
3. Or keep old storage class alongside new one

## Data Migration Strategies

### For Stateless Applications
- Simply redeploy to new cluster
- No data migration needed

### For Stateful Applications with EBS Volumes

#### Option 1: Snapshot and Restore
```bash
# 1. Create snapshot of existing volume
aws ec2 create-snapshot --volume-id vol-xxx --description "Migration backup"

# 2. Create volume from snapshot in new cluster's AZ
aws ec2 create-volume --snapshot-id snap-xxx --availability-zone us-east-1a

# 3. Create PV/PVC pointing to new volume
kubectl apply -f pv-from-snapshot.yaml
```

#### Option 2: Application-Level Backup/Restore
```bash
# 1. Backup data using application tools
# Example for PostgreSQL:
kubectl exec -n database postgres-0 -- pg_dump > backup.sql

# 2. Restore in new cluster
kubectl exec -n database postgres-0 -- psql < backup.sql
```

### For Shared File Systems (EFS)
- EFS can be shared across clusters
- Update mount targets if needed
- No data migration required

## Network Migration

### Ingress/Load Balancers

**Old** (ALB Ingress Controller):
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: alb
```

**New** (Auto Mode - already managed by AWS):
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  # No annotations needed
spec:
  ingressClassName: alb  # Use IngressClass instead
```

### Service Migration
- Service definitions typically don't need changes
- LoadBalancer services work the same way
- ClusterIP and NodePort services unchanged

## IAM Migration

### Old: Node Group IAM Role
```
NodeInstanceRole (per node group)
├── AmazonEKSWorkerNodePolicy
├── AmazonEKS_CNI_Policy
├── AmazonEC2ContainerRegistryReadOnly
└── Custom policies
```

### New: Auto Mode Node Role
```
Custom NodeClass Role (created by blueprint)
├── AmazonEKSWorkerNodeMinimalPolicy
├── AmazonEC2ContainerRegistryPullOnly
└── Custom policies (from additional_node_iam_policies variable)
```

**Migration**: Add your custom policies to `terraform.tfvars`:
```hcl
additional_node_iam_policies = [
  "arn:aws:iam::aws:policy/YourCustomPolicy"
]
```

### IRSA (IAM Roles for Service Accounts)
- IRSA continues to work the same way
- No changes needed to service account configurations
- OIDC provider is still created

## Monitoring & Logging Migration

### CloudWatch Container Insights
```bash
# Same setup works for Auto Mode
# Deploy using FluentBit and CloudWatch agent
kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/quickstart/cwagent-fluentd-quickstart.yaml
```

### Application Logging
- No changes needed
- Continue using existing logging solutions
- (FluentBit, Fluentd, Logstash, etc.)

## Step-by-Step Migration Example

### Example: Migrating a Sample Web Application

#### 1. Current State (Old Cluster)
```bash
# Export current deployment
kubectl get deployment web-app -n production -o yaml > web-app-old.yaml
kubectl get service web-app -n production -o yaml > web-app-svc.yaml
kubectl get ingress web-app -n production -o yaml > web-app-ingress.yaml
```

#### 2. Adapt for Auto Mode

Create `web-app-new.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      # NEW: Add node selector for Auto Mode
      nodeSelector:
        NodeGroupType: amd64
      # NEW: Add toleration
      tolerations:
        - key: amd64
          effect: NoSchedule
      containers:
        - name: web-app
          image: my-web-app:v1.0
          # NEW: Explicit resource requests
          resources:
            requests:
              cpu: "500m"
              memory: "512Mi"
            limits:
              cpu: "1000m"
              memory: "1Gi"
---
apiVersion: v1
kind: Service
metadata:
  name: web-app
  namespace: production
spec:
  # Service stays the same
  selector:
    app: web-app
  ports:
    - port: 80
      targetPort: 8080
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-app
  namespace: production
spec:
  # NEW: Use IngressClass
  ingressClassName: alb
  rules:
    - host: app.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: web-app
                port:
                  number: 80
```

#### 3. Deploy to New Cluster
```bash
# Configure kubectl for new cluster
aws eks update-kubeconfig --name new-auto-mode-cluster

# Create namespace
kubectl create namespace production

# Deploy
kubectl apply -f web-app-new.yaml

# Verify
kubectl get pods -n production
kubectl get ingress -n production
```

#### 4. Traffic Cutover
```bash
# Get new ALB URL
NEW_ALB=$(kubectl get ingress web-app -n production -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Update DNS (example with Route53)
aws route53 change-resource-record-sets --hosted-zone-id Z123 --change-batch '{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "app.example.com",
      "Type": "CNAME",
      "TTL": 60,
      "ResourceRecords": [{"Value": "'$NEW_ALB'"}]
    }
  }]
}'
```

## Validation Checklist

After migration, verify:

- [ ] All pods are running
- [ ] Nodes are auto-provisioning correctly
- [ ] Storage is accessible
- [ ] Network connectivity works
- [ ] Ingress/load balancers are functional
- [ ] Monitoring and logging operational
- [ ] RBAC and permissions correct
- [ ] Application functionality validated
- [ ] Performance metrics acceptable
- [ ] Auto-scaling working as expected

## Rollback Plan

### If Issues Arise During Blue/Green Migration:
1. Stop directing new traffic to new cluster
2. Route all traffic back to old cluster
3. Investigate and fix issues
4. Retry migration when ready

### If Issues After In-Place Migration:
1. Have recent Terraform state backup
2. Keep old cluster definition for quick recreation
3. Restore from backups
4. Recreate old cluster if needed

## Cost Comparison

### Old Cluster (Managed Node Groups)
- EC2 instances (fixed sizes)
- Over-provisioned for peak load
- Idle capacity during low usage

### New Cluster (Auto Mode)
- Right-sized instances automatically
- Scales down when not needed
- Potential 20-40% cost savings
- EKS Auto Mode: $0.10/hour cluster fee (same as regular EKS)

## Timeline Estimation

### Small Cluster (< 50 nodes, < 100 apps)
- Planning: 1-2 weeks
- Migration: 1 week
- Validation: 1 week
- **Total**: 3-4 weeks

### Medium Cluster (50-200 nodes, 100-500 apps)
- Planning: 2-3 weeks
- Migration: 2-3 weeks
- Validation: 2 weeks
- **Total**: 6-8 weeks

### Large Cluster (> 200 nodes, > 500 apps)
- Planning: 4-6 weeks
- Migration: 4-6 weeks
- Validation: 4 weeks
- **Total**: 12-16 weeks

## Common Pitfalls to Avoid

1. **Not setting resource requests** - Karpenter needs them for scheduling
2. **Hardcoded node names** - Nodes are ephemeral in Auto Mode
3. **Missing taints/tolerations** - Pods won't schedule on custom node pools
4. **Insufficient testing** - Validate in dev/staging first
5. **Ignoring monitoring** - Set up observability before migration
6. **Poor data backup** - Always backup before migration

## Support and Resources

- **Blueprint Documentation**: See README.md
- **AWS EKS Auto Mode Docs**: https://docs.aws.amazon.com/eks/latest/userguide/automode.html
- **Karpenter Migration Guide**: https://karpenter.sh/docs/migration/
- **AWS Support**: Contact for migration assistance

## Summary

Migrating to EKS Auto Mode can provide significant operational benefits:
- ✅ Reduced management overhead
- ✅ Better resource utilization
- ✅ Automatic scaling and optimization
- ✅ Cost savings potential

This blueprint makes the migration straightforward by providing a well-tested, production-ready foundation for your new Auto Mode cluster.

---

**Need Help?** Review the full documentation in README.md or consult AWS support for enterprise migrations.
