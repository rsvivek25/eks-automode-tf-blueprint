provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge(
      var.tags,
      {
        ManagedBy = "Terraform"
        Blueprint = "EKS-AutoMode"
      }
    )
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks", "get-token",
        "--cluster-name", module.eks.cluster_name,
        "--region", var.aws_region
      ]
    }
  }
}

provider "kubectl" {
  apply_retry_count      = 5
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks", "get-token",
      "--cluster-name", module.eks.cluster_name,
      "--region", var.aws_region
    ]
  }
}

################################################################################
# Data Sources
################################################################################

data "aws_vpc" "existing" {
  id = var.vpc_id
}

# Subnet discovery via tags (only used if private_subnet_ids is empty)
data "aws_subnets" "private" {
  count = length(var.private_subnet_ids) == 0 ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  tags = var.private_subnet_tags
}

################################################################################
# Local Variables
################################################################################

locals {
  # Use explicit subnet IDs if provided, otherwise discover via tags
  subnet_ids = length(var.private_subnet_ids) > 0 ? var.private_subnet_ids : data.aws_subnets.private[0].ids

  # Determine which default node pools to enable based on variable value
  default_node_pools = (
    lower(var.enable_default_node_pools) == "both" || lower(var.enable_default_node_pools) == "true" ? ["general-purpose", "system"] :
    lower(var.enable_default_node_pools) == "general-purpose" ? ["general-purpose"] :
    lower(var.enable_default_node_pools) == "system" ? ["system"] :
    [] # "none" or "false"
  )
}

################################################################################
# EKS Cluster
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.8"

  name             = var.cluster_name
  kubernetes_version  = var.cluster_version

  # EKS Upgrade Policy - Standard or Extended Support
  # Standard: 14 months of support (free)
  # Extended: Up to 26 months of support (additional cost)
  upgrade_policy = {
    support_type = var.cluster_upgrade_support_type
  }

  # Cluster endpoint access
  endpoint_public_access  = var.cluster_endpoint_public_access
  endpoint_private_access = var.cluster_endpoint_private_access

  # Additional CIDR blocks that can access the cluster endpoint
  endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  # Use existing VPC
  vpc_id     = var.vpc_id
  subnet_ids = local.subnet_ids

  # Enable cluster creator admin permissions
  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions

  # Enable EKS Auto Mode
  compute_config = {
    enabled    = true
    node_pools = local.default_node_pools
  }

  # Envelope encryption for Kubernetes secrets
  encryption_config = var.enable_secrets_encryption ? {
    provider_key_arn = var.kms_key_arn != "" ? var.kms_key_arn : aws_kms_key.eks[0].arn
    resources        = ["secrets"]
  } : {}

  # Enable ARC Zonal Shift for improved availability
  # Allows AWS to automatically shift traffic away from impaired AZs
  zonal_shift_config = var.enable_zonal_shift ? {
    enabled = true
  } : {}

  # Cluster deletion protection
  # Prevents accidental deletion of the EKS cluster via AWS Console or CLI
  # You can still destroy via Terraform (Terraform manages this setting)
  deletion_protection = var.enable_cluster_deletion_protection

  # Additional security groups to attach to the cluster
  additional_security_group_ids = var.create_additional_security_group ? [aws_security_group.additional[0].id] : []

  # Control plane logging to CloudWatch
  enabled_log_types              = var.enable_cluster_control_plane_logging ? var.cluster_enabled_log_types : []
  cloudwatch_log_group_retention_in_days = var.cloudwatch_log_group_retention_in_days
  cloudwatch_log_group_kms_key_id   = var.cloudwatch_log_group_kms_key_id
  cloudwatch_log_group_class     = var.cloudwatch_log_group_class

  # Access entries for custom node classes
  access_entries = {
    custom_nodeclass_access = {
      principal_arn = aws_iam_role.custom_nodeclass_role.arn
      type          = "EC2"

      policy_associations = {
        auto = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAutoNodePolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  # Cluster add-ons
  addons = var.cluster_addons

  tags = var.tags
}

################################################################################
# KMS Key for EKS Secrets Envelope Encryption (Optional)
################################################################################

resource "aws_kms_key" "eks" {
  count = var.enable_secrets_encryption && var.kms_key_arn == "" ? 1 : 0

  description             = "KMS key for EKS cluster ${var.cluster_name} secrets envelope encryption"
  deletion_window_in_days = var.kms_key_deletion_window
  enable_key_rotation     = var.kms_enable_key_rotation

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-eks-secrets"
    }
  )
}

resource "aws_kms_alias" "eks" {
  count = var.enable_secrets_encryption && var.kms_key_arn == "" ? 1 : 0

  name          = "alias/${var.cluster_name}-eks-secrets"
  target_key_id = aws_kms_key.eks[0].key_id
}

# KMS Key Policy - Allow EKS to use the key
resource "aws_kms_key_policy" "eks" {
  count = var.enable_secrets_encryption && var.kms_key_arn == "" ? 1 : 0

  key_id = aws_kms_key.eks[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow EKS to use the key"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:CreateGrant"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "eks.${var.aws_region}.amazonaws.com"
          }
        }
      }
    ]
  })
}

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}

################################################################################
# Additional Security Group (Optional)
################################################################################

resource "aws_security_group" "additional" {
  count = var.create_additional_security_group ? 1 : 0

  name        = var.additional_security_group_name != "" ? var.additional_security_group_name : "${var.cluster_name}-additional-sg"
  description = var.additional_security_group_description
  vpc_id      = var.vpc_id

  # Default egress rule - allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(
    var.tags,
    {
      Name = var.additional_security_group_name != "" ? var.additional_security_group_name : "${var.cluster_name}-additional-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Ingress rules for the additional security group
resource "aws_security_group_rule" "additional_ingress" {
  for_each = var.create_additional_security_group ? {
    for idx, rule in var.additional_security_group_ingress_rules :
    "${rule.protocol}-${rule.from_port}-${rule.to_port}" => rule
  } : {}

  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = var.additional_security_group_ingress_cidr_blocks
  description       = each.value.description
  security_group_id = aws_security_group.additional[0].id
}

################################################################################
# IAM Role for Custom NodeClass Nodes
################################################################################

resource "aws_iam_role" "custom_nodeclass_role" {
  name = "${var.cluster_name}-AmazonEKSAutoNodeRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Attach required IAM policies to the custom node role
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodeMinimalPolicy"
  role       = aws_iam_role.custom_nodeclass_role.name
}

resource "aws_iam_role_policy_attachment" "ecr_pull_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
  role       = aws_iam_role.custom_nodeclass_role.name
}

# Optional: Attach additional custom policies
resource "aws_iam_role_policy_attachment" "custom_policies" {
  for_each = toset(var.additional_node_iam_policies)

  policy_arn = each.value
  role       = aws_iam_role.custom_nodeclass_role.name
}
