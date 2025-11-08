################################################################################
# Example terraform.tfvars for EKS Auto Mode Blueprint
# Copy this file to terraform.tfvars and customize for your environment
################################################################################

# AWS Configuration
aws_region   = "us-east-1"
cluster_name = "eks-auto-cluster"

# Existing VPC Configuration
# Replace with your actual VPC ID
vpc_id = "vpc-0457de39c6afcb5c5"

# Private Subnet IDs (REQUIRED)
# Subnets must be in at least 2 different Availability Zones
# These subnets will be automatically tagged with "kubernetes.io/role/{cluster_name}" = "1"
# for discovery by NodeClass and other Kubernetes resources
private_subnet_ids = [
  "subnet-09e629910c9529eb8",  # us-east-1a (private subnet)
  "subnet-08065b66a7cb1795b",  # us-east-1b (private subnet)
  "subnet-089e4b2476ba9754a",  # us-east-1c (private subnet) - optional but recommended
]

# Cluster Configuration
cluster_version = "1.33"

# EKS Upgrade Policy
# STANDARD: 14 months support (free) - Recommended
# EXTENDED: 26 months support (~$438/month additional cost)
# Use EXTENDED only if you cannot upgrade within 14 months
cluster_upgrade_support_type = "STANDARD"

# Cluster Endpoint Access
# For production, set cluster_endpoint_public_access = false
# and use a bastion host or VPN for access
cluster_endpoint_public_access  = false
cluster_endpoint_private_access = true

# If public access is enabled, restrict to specific CIDR blocks
cluster_endpoint_public_access_cidrs = [
  # "YOUR_OFFICE_IP/32",
  # "YOUR_VPN_CIDR/24"
]

# Enable default Auto Mode node pools
# Options: "none", "system", "general-purpose", "both"
# - "none" or "false": No default node pools (use only custom node pools)
# - "system": Enable only the system node pool (for system workloads)
# - "general-purpose": Enable only the general-purpose node pool
# - "both" or "true": Enable both system and general-purpose node pools
enable_default_node_pools = "system"

# Additional Security Group (Optional)
# Create an additional security group attached to the EKS cluster
# Useful for allowing traffic from specific sources (on-prem, bastion hosts, etc.)
create_additional_security_group = true

# Security group name (defaults to <cluster_name>-additional-sg if not specified)
# additional_security_group_name = "my-eks-additional-sg"

# CIDR blocks allowed to access the cluster through the additional security group
additional_security_group_ingress_cidr_blocks = [
   "192.168.0.0/16"    # VPN network
]

# Ingress rules for the additional security group
# Default: HTTPS (443) access
# Customize as needed for your use case
additional_security_group_ingress_rules = [
  {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    description = "All traffic within VPC"
  }
]

# Secrets Encryption (Envelope Encryption)
# Enable KMS encryption for Kubernetes secrets
enable_secrets_encryption = true

# Option 1: Let Terraform create a new KMS key (recommended)
kms_key_arn = ""

# Option 2: Use existing KMS key (uncomment and provide ARN)
# kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"

# KMS key settings (only applies when creating new key)
kms_key_deletion_window = 30  # Days before key deletion (7-30)
kms_enable_key_rotation = true  # Enable automatic key rotation

# High Availability - ARC Zonal Shift
# Automatically shift traffic away from impaired Availability Zones
# Recommended: true for production clusters
enable_zonal_shift = true

# Cluster Deletion Protection
# Prevents accidental deletion via AWS Console/CLI
# Terraform can still destroy the cluster
# Recommended: true for production clusters
enable_cluster_deletion_protection = true

# Control Plane Logging to CloudWatch
# Enable logging for troubleshooting, security, and compliance
enable_cluster_control_plane_logging = true

# Log types to enable (choose based on your needs)
# Options: api, audit, authenticator, controllerManager, scheduler
# Production recommended: ["api", "audit", "authenticator"]
# All logs (security/compliance): ["api", "audit", "authenticator", "controllerManager", "scheduler"]
# Minimal (cost-conscious): ["audit", "authenticator"]
cluster_enabled_log_types = ["api", "audit", "authenticator"]

# CloudWatch log retention (days)
# Production: 90-365, Compliance: 365+, Development: 7-30
cloudwatch_log_group_retention_in_days = 7

# CloudWatch log class
# STANDARD: Full features, higher cost
# INFREQUENT_ACCESS: 50% cheaper storage, use if rarely queried
cloudwatch_log_group_class = "INFREQUENT_ACCESS"

# Optional: Use KMS to encrypt CloudWatch Logs
# cloudwatch_log_group_kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"

# Auto Mode Features
enable_custom_nodeclasses  = true
enable_custom_nodepools    = true
enable_ebs_storageclass    = true
enable_alb_ingressclass    = true

# Additional IAM policies for node role (optional)
# Add any custom IAM policy ARNs needed by your workloads
additional_node_iam_policies = [
  # "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
  # "arn:aws:iam::123456789012:policy/CustomPolicy"
]

# Resource Tags
tags = {
  Environment = "pilot"
  Project     = "eks-automode"
  ManagedBy   = "Terraform"
  Owner       = "platform-team"
  CostCenter  = "engineering"
}

################################################################################
# Advanced Configuration (Optional)
# Uncomment and customize as needed
################################################################################

# Custom NodeClass YAML files
custom_nodeclass_yamls = [
  "nodeclass-basic.yaml"
]

# Custom NodePool YAML files
custom_nodepool_yamls = [
  "nodepool-amd64.yaml",
]

# StorageClass YAML files
storageclass_yamls = [
  "ebs-storageclass.yaml"
]

# IngressClass YAML files
ingressclass_yamls = [
  "alb-ingressclass-internal.yaml",
  "alb-ingressclassParams-internal.yaml"
]

