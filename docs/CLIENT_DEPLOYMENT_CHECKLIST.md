# Client Environment Deployment Checklist

This checklist helps ensure consistent and successful deployments across different client environments.

## Pre-Deployment Assessment

### Client Information
- [ ] Client name: ________________
- [ ] AWS Account ID: ________________
- [ ] Environment: □ Dev □ Staging □ Production
- [ ] Deployment date: ________________
- [ ] Deployed by: ________________

### AWS Account Verification
- [ ] AWS account access confirmed
- [ ] IAM permissions verified (EKS, EC2, VPC, IAM)
- [ ] AWS CLI configured with correct profile
- [ ] MFA enabled (if required)
- [ ] Service quotas checked (EC2 instances, EIPs, VPCs)

### VPC Assessment
- [ ] VPC ID documented: ________________
- [ ] VPC CIDR range: ________________
- [ ] Number of availability zones: ________________
- [ ] Private subnet IDs: ________________
- [ ] Private subnet CIDR blocks: ________________
- [ ] NAT Gateway configured: □ Yes □ No
- [ ] Internet Gateway present: □ Yes □ No
- [ ] VPC DNS support enabled: □ Yes □ No
- [ ] VPC DNS hostnames enabled: □ Yes □ No

### Subnet Tagging Verification
- [ ] Private subnets tagged for internal-elb
- [ ] Tag key: ________________
- [ ] Tag value: ________________
- [ ] Subnets span multiple AZs: □ Yes □ No

## Configuration Preparation

### Cluster Configuration
- [ ] Cluster name decided: ________________
- [ ] Kubernetes version selected: ________________
- [ ] Cluster endpoint access:
  - [ ] Public access: □ Enabled □ Disabled
  - [ ] Private access: □ Enabled □ Disabled
  - [ ] Public CIDR allowlist: ________________

### Node Pool Selection
- [ ] AMD64 node pool: □ Enabled □ Disabled
- [ ] Graviton (ARM64) node pool: □ Enabled □ Disabled
- [ ] GPU node pool: □ Enabled □ Disabled
- [ ] Spot instances: □ Enabled □ Disabled
- [ ] Custom node pools: ________________

### Storage Requirements
- [ ] EBS storage class required: □ Yes □ No
- [ ] Storage encryption required: □ Yes □ No
- [ ] Storage type (gp3, io1, etc.): ________________
- [ ] Default storage size: ________________

### Networking Requirements
- [ ] ALB ingress required: □ Yes □ No
- [ ] ALB scheme: □ Internet-facing □ Internal
- [ ] NLB required: □ Yes □ No
- [ ] Custom ingress requirements: ________________

### Security Requirements
- [ ] Encryption at rest required: □ Yes □ No
- [ ] Encryption in transit required: □ Yes □ No
- [ ] Compliance frameworks: ________________
- [ ] Security groups reviewed: □ Yes □ No
- [ ] Network policies required: □ Yes □ No

### IAM Requirements
- [ ] Additional IAM policies needed: □ Yes □ No
- [ ] Policy ARNs: ________________
- [ ] Service account roles required: □ Yes □ No
- [ ] OIDC provider required: □ Yes □ No

### Tagging Strategy
- [ ] Environment tag: ________________
- [ ] Project tag: ________________
- [ ] Owner tag: ________________
- [ ] Cost center tag: ________________
- [ ] Additional tags: ________________

## Deployment Steps

### Step 1: Environment Setup
- [ ] Clone/download blueprint
- [ ] Navigate to terraform-eks directory
- [ ] Copy terraform.tfvars.example to terraform.tfvars
- [ ] Open terraform.tfvars in editor

### Step 2: Configuration
- [ ] Set aws_region
- [ ] Set cluster_name
- [ ] Set vpc_id
- [ ] Configure private_subnet_tags
- [ ] Set cluster_version
- [ ] Configure cluster endpoint access
- [ ] Set enable_default_node_pools
- [ ] Configure custom node pools
- [ ] Add resource tags
- [ ] Review additional_node_iam_policies
- [ ] Save terraform.tfvars

### Step 3: Validation
- [ ] Run `terraform init`
- [ ] Check for provider download errors
- [ ] Run `terraform validate`
- [ ] Fix any validation errors
- [ ] Run `terraform plan`
- [ ] Review planned changes
- [ ] Verify resource counts
- [ ] Check for unexpected changes

### Step 4: Deployment
- [ ] Run `terraform apply`
- [ ] Review apply output
- [ ] Confirm with 'yes'
- [ ] Monitor deployment progress
- [ ] Note deployment time: ________ minutes
- [ ] Check for errors
- [ ] Save terraform output

### Step 5: Post-Deployment Verification
- [ ] Update kubeconfig: `aws eks update-kubeconfig ...`
- [ ] Test kubectl connection: `kubectl cluster-info`
- [ ] Verify node pools: `kubectl get nodepools`
- [ ] Verify node classes: `kubectl get nodeclasses -A`
- [ ] Check storage classes: `kubectl get storageclass`
- [ ] Check ingress classes: `kubectl get ingressclass`
- [ ] Review cluster endpoints
- [ ] Verify OIDC provider

### Step 6: Application Deployment
- [ ] Deploy sample application (optional)
- [ ] Wait for node provisioning
- [ ] Verify pods running: `kubectl get pods -A`
- [ ] Check PVCs created: `kubectl get pvc -A`
- [ ] Verify ingress/ALB created
- [ ] Test application access
- [ ] Clean up sample app (if deployed)

## Documentation

### Cluster Information
- [ ] Document cluster endpoint URL
- [ ] Document OIDC provider ARN
- [ ] Save kubeconfig configuration
- [ ] Document node IAM role ARN
- [ ] Save kubectl access commands

### Access Information
- [ ] Document bastion host (if used)
- [ ] Document VPN requirements (if any)
- [ ] Create access runbook
- [ ] Share kubectl configuration guide
- [ ] Document emergency access procedures

### Monitoring & Logging
- [ ] Configure CloudWatch Container Insights
- [ ] Set up log aggregation
- [ ] Configure metrics collection
- [ ] Set up alerts
- [ ] Create monitoring dashboard

### Backup & Recovery
- [ ] Document backup procedures
- [ ] Set up Terraform state backup
- [ ] Create disaster recovery plan
- [ ] Document cluster recreation steps
- [ ] Test recovery procedures

## Client Handoff

### Training
- [ ] kubectl basics training provided
- [ ] Node pool selection guide shared
- [ ] Storage provisioning explained
- [ ] Ingress configuration covered
- [ ] Troubleshooting guide provided

### Documentation Delivery
- [ ] README.md shared
- [ ] QUICKSTART.md shared
- [ ] Configuration details documented
- [ ] Architecture diagram provided
- [ ] Runbooks created

### Credentials & Access
- [ ] AWS access configured for client team
- [ ] kubectl access configured
- [ ] Terraform state access configured
- [ ] Git repository access granted (if applicable)
- [ ] Documentation repository access

### Support Transition
- [ ] Support contact information shared
- [ ] Escalation procedures documented
- [ ] Known issues documented
- [ ] Future enhancement backlog shared
- [ ] Maintenance windows scheduled

## Post-Deployment Monitoring (First 7 Days)

### Day 1
- [ ] Check cluster health
- [ ] Monitor node provisioning
- [ ] Verify auto-scaling working
- [ ] Review CloudWatch logs
- [ ] Check for errors/warnings

### Day 2-3
- [ ] Monitor resource utilization
- [ ] Review cost allocation
- [ ] Check node pool efficiency
- [ ] Verify backup processes
- [ ] Review security posture

### Day 4-7
- [ ] Analyze usage patterns
- [ ] Optimize node pool configurations
- [ ] Review and adjust resource limits
- [ ] Fine-tune auto-scaling
- [ ] Update documentation with learnings

## Cost Optimization

### Initial Review
- [ ] Review instance types used
- [ ] Analyze utilization metrics
- [ ] Check for underutilized resources
- [ ] Consider Savings Plans/Reserved Instances
- [ ] Set up cost alerts

### Ongoing Optimization
- [ ] Weekly cost review scheduled
- [ ] Right-sizing recommendations reviewed
- [ ] Spot instance opportunities evaluated
- [ ] Graviton migration considered
- [ ] Unused resources cleaned up

## Security Hardening

### Network Security
- [ ] Network policies implemented
- [ ] Security groups reviewed
- [ ] Private endpoints verified
- [ ] TLS/SSL configured
- [ ] VPC flow logs enabled

### Access Control
- [ ] RBAC policies configured
- [ ] Service accounts created
- [ ] Pod security policies/standards applied
- [ ] IAM roles properly scoped
- [ ] MFA enforced for admin access

### Compliance
- [ ] Audit logging enabled
- [ ] Compliance controls verified
- [ ] Vulnerability scanning configured
- [ ] Secrets management implemented
- [ ] Regular security reviews scheduled

## Troubleshooting

### Common Issues Encountered
Issue 1: ________________
Resolution: ________________

Issue 2: ________________
Resolution: ________________

Issue 3: ________________
Resolution: ________________

## Sign-off

### Technical Validation
- [ ] All deployment steps completed
- [ ] All verifications passed
- [ ] Documentation complete
- [ ] Client training completed
- [ ] Support transition complete

**Deployed by**: ________________  
**Date**: ________________  
**Signature**: ________________

**Approved by**: ________________  
**Date**: ________________  
**Signature**: ________________

### Client Acceptance
- [ ] Cluster meets requirements
- [ ] Documentation satisfactory
- [ ] Training adequate
- [ ] Support procedures clear
- [ ] Ready for production use

**Client Representative**: ________________  
**Date**: ________________  
**Signature**: ________________

## Notes & Comments

Additional deployment notes:
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________

Lessons learned:
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________

Future improvements:
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
