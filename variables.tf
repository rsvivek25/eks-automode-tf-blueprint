################################################################################
# General Variables
################################################################################

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.31"
}

variable "cluster_upgrade_support_type" {
  description = <<-EOT
    EKS cluster upgrade support policy.
    Options:
      - "STANDARD": 14 months of support after release (free)
      - "EXTENDED": Up to 26 months of support (additional hourly cost per cluster)
    
    Standard Support Timeline:
      - Kubernetes 1.31: Supported until ~March 2026
      - 14 months from release date
    
    Extended Support Timeline:
      - Additional 12 months beyond standard support
      - Total: 26 months from release
      - Cost: $0.60/hour per cluster (~$438/month)
    
    Recommendation: Use STANDARD and upgrade regularly. Use EXTENDED only if you cannot upgrade within 14 months.
  EOT
  type        = string
  default     = "STANDARD"

  validation {
    condition     = contains(["STANDARD", "EXTENDED"], upper(var.cluster_upgrade_support_type))
    error_message = "cluster_upgrade_support_type must be either 'STANDARD' or 'EXTENDED'."
  }
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

################################################################################
# Security Group Variables
################################################################################

variable "create_additional_security_group" {
  description = "Whether to create an additional security group for the EKS cluster"
  type        = bool
  default     = false
}

variable "additional_security_group_name" {
  description = "Name of the additional security group (defaults to cluster_name-additional-sg if not specified)"
  type        = string
  default     = ""
}

variable "additional_security_group_description" {
  description = "Description for the additional security group"
  type        = string
  default     = "Additional security group for EKS cluster"
}

variable "additional_security_group_ingress_cidr_blocks" {
  description = <<-EOT
    List of CIDR blocks allowed for inbound traffic to the additional security group.
    Example: ["10.0.0.0/8", "172.16.0.0/12"]
    
    Common use cases:
    - Allow traffic from on-premises networks
    - Allow traffic from specific VPCs or subnets
    - Allow traffic from bastion hosts or jump servers
  EOT
  type        = list(string)
  default     = []
}

variable "additional_security_group_ingress_rules" {
  description = <<-EOT
    List of ingress rules for the additional security group.
    Each rule should specify: from_port, to_port, protocol, and description.
    CIDR blocks are specified via additional_security_group_ingress_cidr_blocks.
    
    Example:
    [
      {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        description = "HTTPS access from corporate network"
      },
      {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        description = "SSH access from bastion hosts"
      }
    ]
  EOT
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    description = string
  }))
  default = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "HTTPS access"
    }
  ]
}

################################################################################
# VPC Variables (Existing VPC)
################################################################################

variable "vpc_id" {
  description = "ID of the existing VPC where EKS cluster will be created"
  type        = string
}

variable "private_subnet_ids" {
  description = <<-EOT
    List of private subnet IDs to use for the EKS cluster.
    Must be in at least 2 different Availability Zones.
    These subnets will be automatically tagged with "kubernetes.io/role/{cluster_name}" = "1" for discovery.
  EOT
  type        = list(string)
  
  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "At least 2 private subnet IDs are required for high availability across multiple Availability Zones."
  }
}

################################################################################
# EKS Cluster Configuration
################################################################################

variable "cluster_endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = false
}

variable "cluster_endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks that can access the public API server endpoint"
  type        = list(string)
  default     = []
}

variable "enable_cluster_creator_admin_permissions" {
  description = "Enable cluster creator admin permissions"
  type        = bool
  default     = true
}

################################################################################
# Control Plane Logging
################################################################################

variable "enable_cluster_control_plane_logging" {
  description = "Enable EKS control plane logging to CloudWatch Logs"
  type        = bool
  default     = true
}

variable "cluster_enabled_log_types" {
  description = <<-EOT
    List of control plane logging types to enable. Valid values: api, audit, authenticator, controllerManager, scheduler
    
    Log Types:
    - api: API server logs - All API server requests and responses
    - audit: Audit logs - Kubernetes audit logs showing who did what and when
    - authenticator: Authenticator logs - Authentication attempts to the cluster
    - controllerManager: Controller manager logs - Logs from the Kubernetes controller manager
    - scheduler: Scheduler logs - Logs from the Kubernetes scheduler
    
    Recommendations:
    - Production: Enable ["api", "audit", "authenticator"] at minimum
    - Security/Compliance: Enable all log types
    - Cost-conscious: Enable ["audit", "authenticator"] only
    - Development: Can disable all to save costs
  EOT
  type        = list(string)
  default     = ["api", "audit", "authenticator"]

  validation {
    condition = alltrue([
      for log_type in var.cluster_enabled_log_types :
      contains(["api", "audit", "authenticator", "controllerManager", "scheduler"], log_type)
    ])
    error_message = "Invalid log type. Valid values: api, audit, authenticator, controllerManager, scheduler."
  }
}

variable "cloudwatch_log_group_retention_in_days" {
  description = <<-EOT
    Number of days to retain control plane logs in CloudWatch Logs.
    Valid values: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653
    
    Recommendations:
    - Production: 90-365 days
    - Compliance: 365+ days (check your requirements)
    - Development: 7-30 days
  EOT
  type        = number
  default     = 90

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.cloudwatch_log_group_retention_in_days)
    error_message = "Invalid retention period. See variable description for valid values."
  }
}

variable "cloudwatch_log_group_kms_key_id" {
  description = "KMS key ID to encrypt CloudWatch Logs (optional). Leave empty to use AWS managed keys."
  type        = string
  default     = ""
}

variable "cloudwatch_log_group_class" {
  description = <<-EOT
    Log class for the CloudWatch Log Group.
    - STANDARD: Default log class with full features
    - INFREQUENT_ACCESS: Lower cost for infrequently accessed logs (50% cheaper storage, same ingestion cost)
    
    Use INFREQUENT_ACCESS if:
    - Logs are primarily for compliance/audit (rarely queried)
    - You query logs less than once per month
    - Cost optimization is a priority
  EOT
  type        = string
  default     = "STANDARD"

  validation {
    condition     = contains(["STANDARD", "INFREQUENT_ACCESS"], var.cloudwatch_log_group_class)
    error_message = "cloudwatch_log_group_class must be either 'STANDARD' or 'INFREQUENT_ACCESS'."
  }
}

variable "enable_default_node_pools" {
  description = <<-EOT
    Control which default EKS Auto Mode node pools to enable.
    Options:
      - "none" or false: No default node pools (use only custom node pools)
      - "system": Enable only the system node pool
      - "general-purpose": Enable only the general-purpose node pool
      - "both" or true: Enable both system and general-purpose node pools
  EOT
  type        = string
  default     = "none"

  validation {
    condition     = contains(["none", "system", "general-purpose", "both", "true", "false"], lower(var.enable_default_node_pools))
    error_message = "enable_default_node_pools must be one of: 'none', 'system', 'general-purpose', 'both', 'true', or 'false'."
  }
}

variable "cluster_addons" {
  description = "Map of cluster addon configurations to enable"
  type        = any
  default = {
    # EKS Auto Mode manages EBS CSI driver and AWS Load Balancer Controller
    # You can add other addons here as needed
    # Example:
    # coredns = {
    #   most_recent = true
    # }
  }
}

################################################################################
# Secrets Encryption Configuration
################################################################################

variable "enable_secrets_encryption" {
  description = "Enable envelope encryption for Kubernetes secrets using AWS KMS"
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "ARN of existing KMS key to use for secrets encryption. Leave empty to create a new key."
  type        = string
  default     = ""
}

variable "kms_key_deletion_window" {
  description = "Number of days before KMS key deletion (7-30 days)"
  type        = number
  default     = 30

  validation {
    condition     = var.kms_key_deletion_window >= 7 && var.kms_key_deletion_window <= 30
    error_message = "KMS key deletion window must be between 7 and 30 days."
  }
}

variable "kms_enable_key_rotation" {
  description = "Enable automatic KMS key rotation (recommended for security)"
  type        = bool
  default     = true
}

################################################################################
# High Availability Configuration
################################################################################

variable "enable_zonal_shift" {
  description = <<-EOT
    Enable AWS Application Recovery Controller (ARC) Zonal Shift.
    Allows AWS to automatically shift traffic away from impaired Availability Zones
    to maintain high availability during AZ impairments.
    Recommended for production clusters.
  EOT
  type        = bool
  default     = true
}

variable "enable_cluster_deletion_protection" {
  description = <<-EOT
    Enable deletion protection for the EKS cluster.
    When enabled, prevents accidental deletion via AWS Console, CLI, or API.
    Terraform can still destroy the cluster (Terraform manages this setting automatically).
    
    Recommended: true for production clusters to prevent accidental deletion.
  EOT
  type        = bool
  default     = true
}

################################################################################
# IAM Configuration
################################################################################

variable "additional_node_iam_policies" {
  description = "Additional IAM policy ARNs to attach to the custom node IAM role"
  type        = list(string)
  default     = []
}

################################################################################
# Auto Mode Configuration
################################################################################

variable "enable_custom_nodeclasses" {
  description = "Enable custom NodeClass configurations"
  type        = bool
  default     = true
}

variable "enable_custom_nodepools" {
  description = "Enable custom NodePool configurations"
  type        = bool
  default     = true
}

variable "enable_ebs_storageclass" {
  description = "Enable custom EBS StorageClass configuration"
  type        = bool
  default     = true
}

variable "enable_alb_ingressclass" {
  description = "Enable ALB IngressClass configuration"
  type        = bool
  default     = true
}

variable "custom_nodeclass_yamls" {
  description = "List of custom NodeClass YAML files to apply"
  type        = list(string)
  default = [
    "nodeclass-basic.yaml",
    "nodeclass-ebs-optimized.yaml"
  ]
}

variable "custom_nodepool_yamls" {
  description = "List of custom NodePool YAML files to apply"
  type        = list(string)
  default = [
    "nodepool-amd64.yaml",
    "nodepool-graviton.yaml"
  ]
}

variable "storageclass_yamls" {
  description = "List of StorageClass YAML files to apply"
  type        = list(string)
  default = [
    "ebs-storageclass.yaml"
  ]
}

variable "ingressclass_yamls" {
  description = "List of IngressClass YAML files to apply"
  type        = list(string)
  default = [
    "alb-ingressclass.yaml",
    "alb-ingressclassParams.yaml",
    "alb-ingressclass-internal.yaml",
    "alb-ingressclassParams-internal.yaml"
  ]
}
