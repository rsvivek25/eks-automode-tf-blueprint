################################################################################
# EKS Auto Mode Configuration
# This file applies NodeClass, NodePool, StorageClass, and IngressClass
# configurations to the EKS Auto Mode cluster
################################################################################

################################################################################
# Apply EBS StorageClass
################################################################################

resource "kubectl_manifest" "storageclass_yamls" {
  for_each = var.enable_ebs_storageclass ? toset(var.storageclass_yamls) : []

  yaml_body = file("${path.module}/eks-automode-config/${each.value}")

  depends_on = [module.eks]
}

################################################################################
# Apply ALB IngressClass and IngressClassParams
# IngressClassParams YAML files are templated to use explicit subnet IDs
################################################################################

resource "kubectl_manifest" "ingressclass_yamls" {
  for_each = var.enable_alb_ingressclass ? toset(var.ingressclass_yamls) : []

  # Use templatefile for IngressClassParams files, regular file for IngressClass
  yaml_body = can(regex("Params", each.value)) ? templatefile("${path.module}/eks-automode-config/${each.value}", {
    subnet_ids = jsonencode(var.private_subnet_ids)
  }) : file("${path.module}/eks-automode-config/${each.value}")

  depends_on = [module.eks]
}

################################################################################
# Apply Custom NodeClass Objects
# NodeClass YAML files are templated - Terraform substitutes variables:
#   - ${node_iam_role_name} → actual IAM role name
#   - ${cluster_name} → actual EKS cluster name
#   - ${subnet_ids} → JSON array of subnet IDs
################################################################################

resource "kubectl_manifest" "custom_nodeclass" {
  for_each = var.enable_custom_nodeclasses ? toset(var.custom_nodeclass_yamls) : []

  # templatefile() replaces ${variable} placeholders in YAML with actual values
  yaml_body = templatefile("${path.module}/eks-automode-config/${each.value}", {
    node_iam_role_name = aws_iam_role.custom_nodeclass_role.name
    cluster_name       = module.eks.cluster_name
    vpc_id             = var.vpc_id
    additional_sg_id   = var.create_additional_security_group ? aws_security_group.additional[0].id : ""
    subnet_ids         = jsonencode(var.private_subnet_ids)
  })

  depends_on = [module.eks]
}

################################################################################
# Apply Custom NodePool Objects
# NodePool YAML files use standard file() - no variable substitution needed
# They reference NodeClass by name, which was created in the step above
################################################################################

resource "kubectl_manifest" "custom_nodepool" {
  for_each = var.enable_custom_nodepools ? toset(var.custom_nodepool_yamls) : []

  yaml_body = file("${path.module}/eks-automode-config/${each.value}")

  depends_on = [
    module.eks,
    kubectl_manifest.custom_nodeclass
  ]
}
