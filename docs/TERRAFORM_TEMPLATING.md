# Terraform Templating Explained

## How Variable Substitution Works in This Blueprint

This blueprint uses Terraform's `templatefile()` function to dynamically substitute values in Kubernetes YAML manifests before applying them to the cluster.

## Files Using Templating

### ✅ NodeClass Files (Templated)

These files have **placeholders** that get substituted:

**Files:**
- `eks-automode-config/nodeclass-basic.yaml`
- `eks-automode-config/nodeclass-ebs-optimized.yaml`

**Placeholders:**
```yaml
role: "${node_iam_role_name}"  # ← Placeholder
subnetSelectorTerms:
  - tags:
      Name: "${cluster_name}-private*"  # ← Placeholder
```

**Terraform substitution** (in `eks-automode-config.tf`):
```hcl
yaml_body = templatefile("${path.module}/eks-automode-config/nodeclass-basic.yaml", {
  node_iam_role_name = aws_iam_role.custom_nodeclass_role.name  # Actual value
  cluster_name       = module.eks.cluster_name                   # Actual value
})
```

**Result after substitution:**
```yaml
role: "my-eks-cluster-AmazonEKSAutoNodeRole"  # ✅ Real IAM role name
subnetSelectorTerms:
  - tags:
      Name: "my-eks-cluster-private*"  # ✅ Real cluster name
```

---

### ❌ Other Files (NOT Templated)

These files are applied **as-is** without variable substitution:

**Files:**
- `eks-automode-config/nodepool-amd64.yaml`
- `eks-automode-config/nodepool-graviton.yaml`
- `eks-automode-config/ebs-storageclass.yaml`
- `eks-automode-config/alb-ingressclass.yaml`
- `eks-automode-config/alb-ingressclassParams.yaml`

**Terraform applies directly:**
```hcl
yaml_body = file("${path.module}/eks-automode-config/nodepool-amd64.yaml")
```

**Why no templating?**
- These files don't need dynamic values
- NodePools reference NodeClasses by static name
- StorageClass and IngressClass are cluster-wide with fixed configuration

---

## The Substitution Process

### Step 1: Terraform Reads Template
```yaml
# nodeclass-basic.yaml
role: "${node_iam_role_name}"
```

### Step 2: Terraform Creates Resources
```hcl
# main.tf creates the IAM role
resource "aws_iam_role" "custom_nodeclass_role" {
  name = "${var.cluster_name}-AmazonEKSAutoNodeRole"
  # ...
}
```

### Step 3: Terraform Substitutes Variables
```hcl
# eks-automode-config.tf
templatefile("nodeclass-basic.yaml", {
  node_iam_role_name = aws_iam_role.custom_nodeclass_role.name
  # Returns: "my-cluster-AmazonEKSAutoNodeRole"
})
```

### Step 4: Terraform Applies to Kubernetes
```yaml
# What Kubernetes receives:
role: "my-cluster-AmazonEKSAutoNodeRole"  # ✅ Actual value
```

---

## Variables Available for Templating

### Currently Used:

| Variable | Source | Example Value |
|----------|--------|---------------|
| `node_iam_role_name` | `aws_iam_role.custom_nodeclass_role.name` | `my-cluster-AmazonEKSAutoNodeRole` |
| `cluster_name` | `module.eks.cluster_name` | `my-eks-cluster` |

### Potentially Useful (Not Currently Used):

| Variable | Source | Example Value |
|----------|--------|---------------|
| `vpc_id` | `var.vpc_id` | `vpc-0123456789abcdef0` |
| `region` | `var.aws_region` | `us-east-1` |
| `cluster_endpoint` | `module.eks.cluster_endpoint` | `https://ABC123.eks.us-east-1.amazonaws.com` |

---

## Adding New Template Variables

### Step 1: Update YAML File
Add placeholder in your YAML:
```yaml
# nodeclass-custom.yaml
spec:
  role: "${node_iam_role_name}"
  tags:
    Region: "${aws_region}"  # ← New placeholder
```

### Step 2: Update Terraform
Pass the variable in `templatefile()`:
```hcl
resource "kubectl_manifest" "custom_nodeclass" {
  yaml_body = templatefile("${path.module}/eks-automode-config/nodeclass-custom.yaml", {
    node_iam_role_name = aws_iam_role.custom_nodeclass_role.name
    aws_region         = var.aws_region  # ← Add new variable
  })
}
```

### Step 3: Apply
Terraform will substitute both variables when applying.

---

## Verification

### Check What Kubernetes Received

After running `terraform apply`, verify the substitution worked:

```bash
# View the NodeClass as applied to Kubernetes
kubectl get nodeclass basic -o yaml

# Check specific field (should show actual role name, not placeholder)
kubectl get nodeclass basic -o jsonpath='{.spec.role}'
# Expected: "my-cluster-AmazonEKSAutoNodeRole"
# NOT: "${node_iam_role_name}"
```

### Terraform Plan Output

When running `terraform plan`, you'll see:
```
# kubectl_manifest.custom_nodeclass["nodeclass-basic.yaml"] will be created
+ resource "kubectl_manifest" "custom_nodeclass" {
    + yaml_body = <<-EOT
        apiVersion: eks.amazonaws.com/v1
        kind: NodeClass
        metadata:
          name: basic
        spec:
          role: "my-cluster-AmazonEKSAutoNodeRole"  # ← Substituted value
```

---

## Common Mistakes to Avoid

### ❌ Wrong: Using file() Instead of templatefile()
```hcl
# This won't work - placeholders will remain literal
yaml_body = file("nodeclass-basic.yaml")
# Result: role: "${node_iam_role_name}" (literal string)
```

### ✅ Correct: Using templatefile()
```hcl
yaml_body = templatefile("nodeclass-basic.yaml", {
  node_iam_role_name = aws_iam_role.custom_nodeclass_role.name
})
# Result: role: "my-cluster-AmazonEKSAutoNodeRole" (actual value)
```

---

### ❌ Wrong: Typo in Placeholder Name
```yaml
# In YAML file
role: "${node_role_name}"  # ← Typo: missing "iam"
```

```hcl
# In Terraform
templatefile("nodeclass.yaml", {
  node_iam_role_name = "..."  # ← Different name
})
# Result: Error - variable not found
```

### ✅ Correct: Exact Match
```yaml
role: "${node_iam_role_name}"  # ← Exact name
```

```hcl
templatefile("nodeclass.yaml", {
  node_iam_role_name = "..."  # ← Matching name
})
```

---

### ❌ Wrong: Missing Variable in templatefile()
```yaml
# YAML file has placeholder
securityGroupSelectorTerms:
  - tags:
      Name: "${cluster_name}-node"
```

```hcl
# But Terraform doesn't provide it
templatefile("nodeclass.yaml", {
  node_iam_role_name = "..."
  # Missing: cluster_name = ...
})
# Result: Error - variable not found
```

### ✅ Correct: Provide All Variables
```hcl
templatefile("nodeclass.yaml", {
  node_iam_role_name = aws_iam_role.custom_nodeclass_role.name
  cluster_name       = module.eks.cluster_name  # ← Provided
})
```

---

## Summary

### For NodeClass Files:
1. ✅ Use `templatefile()` in Terraform
2. ✅ Add `${variable}` placeholders in YAML
3. ✅ Pass all variables to `templatefile()`
4. ✅ Verify with `kubectl get nodeclass -o yaml`

### For Other Files:
1. ✅ Use `file()` in Terraform (no templating needed)
2. ✅ Write final values directly in YAML
3. ✅ No placeholders needed

### The Magic:
Terraform reads YAML → Substitutes variables → Applies to Kubernetes → Everything works! 🎯

---

**Key Takeaway:** The `templatefile()` function in `eks-automode-config.tf` automatically replaces `${placeholders}` in your YAML files with actual values from your Terraform resources **before** applying them to Kubernetes. You don't need to manually edit the YAML files!
