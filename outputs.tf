################################################################################
# EKS Cluster Outputs
################################################################################

output "cluster_id" {
  description = "The name/id of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = module.eks.cluster_arn
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_version" {
  description = "The Kubernetes server version for the cluster"
  value       = module.eks.cluster_version
}

output "cluster_upgrade_support_type" {
  description = "The EKS upgrade support policy (STANDARD or EXTENDED)"
  value       = var.cluster_upgrade_support_type
}

output "cluster_platform_version" {
  description = "The platform version for the cluster"
  value       = module.eks.cluster_platform_version
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "additional_security_group_id" {
  description = "ID of the additional security group attached to the EKS cluster (if created)"
  value       = var.create_additional_security_group ? aws_security_group.additional[0].id : null
}

output "additional_security_group_arn" {
  description = "ARN of the additional security group attached to the EKS cluster (if created)"
  value       = var.create_additional_security_group ? aws_security_group.additional[0].arn : null
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer"
  value       = module.eks.cluster_oidc_issuer_url
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider for EKS"
  value       = module.eks.oidc_provider_arn
}

################################################################################
# IAM Role Outputs
################################################################################

output "custom_nodeclass_role_arn" {
  description = "ARN of the IAM role used by custom NodeClass nodes"
  value       = aws_iam_role.custom_nodeclass_role.arn
}

output "custom_nodeclass_role_name" {
  description = "Name of the IAM role used by custom NodeClass nodes"
  value       = aws_iam_role.custom_nodeclass_role.name
}

################################################################################
# CloudWatch Logs Outputs
################################################################################

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch Log Group for EKS control plane logs"
  value       = var.enable_cluster_control_plane_logging ? "/aws/eks/${var.cluster_name}/cluster" : null
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch Log Group for EKS control plane logs"
  value       = var.enable_cluster_control_plane_logging ? module.eks.cloudwatch_log_group_arn : null
}

output "enabled_cluster_log_types" {
  description = "List of enabled control plane log types"
  value       = var.enable_cluster_control_plane_logging ? var.cluster_enabled_log_types : []
}

################################################################################
# kubectl Configuration
################################################################################

output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = "aws eks --region ${var.aws_region} update-kubeconfig --name ${module.eks.cluster_name}"
}

output "kubeconfig_command" {
  description = "Command to update kubeconfig for cluster access"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

################################################################################
# Auto Mode Configuration Outputs
################################################################################

output "auto_mode_enabled" {
  description = "Whether EKS Auto Mode is enabled"
  value       = true
}

output "default_node_pools_enabled" {
  description = "Whether default Auto Mode node pools are enabled"
  value       = var.enable_default_node_pools
}

output "custom_nodeclasses_enabled" {
  description = "Whether custom NodeClasses are enabled"
  value       = var.enable_custom_nodeclasses
}

output "custom_nodepools_enabled" {
  description = "Whether custom NodePools are enabled"
  value       = var.enable_custom_nodepools
}

################################################################################
# Secrets Encryption Outputs
################################################################################

output "secrets_encryption_enabled" {
  description = "Whether envelope encryption for secrets is enabled"
  value       = var.enable_secrets_encryption
}

output "kms_key_id" {
  description = "KMS key ID used for secrets encryption (if created by Terraform)"
  value       = var.enable_secrets_encryption && var.kms_key_arn == "" ? aws_kms_key.eks[0].key_id : null
}

output "kms_key_arn" {
  description = "KMS key ARN used for secrets encryption"
  value       = var.enable_secrets_encryption ? (var.kms_key_arn != "" ? var.kms_key_arn : aws_kms_key.eks[0].arn) : null
}

output "kms_key_alias" {
  description = "KMS key alias (if created by Terraform)"
  value       = var.enable_secrets_encryption && var.kms_key_arn == "" ? aws_kms_alias.eks[0].name : null
}

################################################################################
# High Availability Outputs
################################################################################

output "zonal_shift_enabled" {
  description = "Whether ARC Zonal Shift is enabled for the cluster"
  value       = var.enable_zonal_shift
}

output "cluster_deletion_protection_enabled" {
  description = "Whether deletion protection is enabled for the cluster"
  value       = var.enable_cluster_deletion_protection
}

################################################################################
# VPC Information
################################################################################

output "vpc_id" {
  description = "The ID of the VPC"
  value       = var.vpc_id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs used by the EKS cluster"
  value       = var.private_subnet_ids
}
