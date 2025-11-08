# EKS Secrets Envelope Encryption

## Overview

This blueprint supports **envelope encryption** for Kubernetes secrets using AWS Key Management Service (KMS). This provides an additional layer of security for sensitive data stored in etcd.

## What is Envelope Encryption?

**Envelope encryption** is a security practice where:

1. Your Kubernetes secrets are encrypted using a **Data Encryption Key (DEK)**
2. The DEK itself is encrypted using a **KMS Customer Master Key (CMK)**
3. The encrypted DEK is stored with your data
4. Only the encrypted DEK is sent to KMS for decryption when needed

**Benefits:**
- ✅ Secrets are encrypted at rest in etcd
- ✅ You control the encryption key lifecycle
- ✅ Audit all key usage via CloudTrail
- ✅ Comply with regulatory requirements (HIPAA, PCI-DSS, etc.)
- ✅ Automatic key rotation support

---

## Configuration Options

Your blueprint provides **three options** for secrets encryption:

### Option 1: Terraform-Managed KMS Key (Default - Recommended)

**Most secure and automated approach**

```hcl
# In terraform.tfvars
enable_secrets_encryption = true
kms_key_arn = ""  # Leave empty to create new key
kms_key_deletion_window = 30
kms_enable_key_rotation = true
```

**What happens:**
- ✅ Terraform creates a new KMS Customer Managed Key (CMK)
- ✅ Key is dedicated to this EKS cluster
- ✅ Automatic key rotation enabled (365 days)
- ✅ Key alias: `alias/<cluster-name>-eks-secrets`
- ✅ Proper key policy configured for EKS access
- ✅ 30-day deletion window (recoverable if deleted accidentally)

**Best for:**
- Production environments
- Compliance requirements
- Full control over encryption keys
- Audit requirements

---

### Option 2: Use Existing KMS Key

**Use a pre-existing KMS key**

```hcl
# In terraform.tfvars
enable_secrets_encryption = true
kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
```

**What happens:**
- ✅ Uses your existing KMS key
- ✅ Useful for centralized key management
- ✅ Share key across multiple clusters (if desired)

**Prerequisites:**
Your existing KMS key policy must allow EKS to use it:

```json
{
  "Sid": "Allow EKS to use the key",
  "Effect": "Allow",
  "Principal": {
    "Service": "eks.amazonaws.com"
  },
  "Action": [
    "kms:Decrypt",
    "kms:DescribeKey",
    "kms:CreateGrant"
  ],
  "Resource": "*",
  "Condition": {
    "StringEquals": {
      "kms:ViaService": "eks.<region>.amazonaws.com"
    }
  }
}
```

**Best for:**
- Centralized key management
- Organization-wide KMS key policies
- Shared infrastructure

---

### Option 3: No Envelope Encryption (Not Recommended)

**Use AWS-managed encryption only**

```hcl
# In terraform.tfvars
enable_secrets_encryption = false
```

**What happens:**
- ⚠️ Secrets still encrypted at rest (AWS-managed key)
- ❌ No control over encryption keys
- ❌ Cannot audit key usage
- ❌ Cannot rotate keys
- ❌ Cannot comply with some regulatory requirements

**Best for:**
- Development/testing environments only
- Non-production clusters
- When compliance is not a requirement

---

## Encryption Comparison

| Feature | AWS-Managed | Terraform-Managed CMK | Existing CMK |
|---------|-------------|----------------------|--------------|
| **Secrets encrypted at rest** | ✅ Yes | ✅ Yes | ✅ Yes |
| **Control encryption key** | ❌ No | ✅ Yes | ✅ Yes |
| **Key rotation** | ❌ No control | ✅ Automatic (365d) | ⚠️ Manual |
| **CloudTrail audit logs** | ❌ Limited | ✅ Full | ✅ Full |
| **Compliance friendly** | ⚠️ Limited | ✅ Yes | ✅ Yes |
| **Cost** | Free | ~$1/month + API calls | ~$1/month + API calls |
| **Deletion recovery** | N/A | ✅ 7-30 days | ⚠️ Depends on key |
| **Setup complexity** | Easy | Easy (automated) | Medium |

---

## How It Works

### Encryption Flow

```
1. Application creates a Kubernetes secret
   ↓
2. API server sends plaintext to etcd
   ↓
3. EKS encryption provider intercepts
   ↓
4. EKS calls KMS to encrypt with CMK
   ↓
5. Encrypted data stored in etcd
```

### Decryption Flow

```
1. Application requests secret
   ↓
2. API server retrieves encrypted data from etcd
   ↓
3. EKS encryption provider intercepts
   ↓
4. EKS calls KMS to decrypt with CMK
   ↓
5. Plaintext secret returned to pod
```

---

## Security Best Practices

### ✅ DO

1. **Enable envelope encryption in production**
   ```hcl
   enable_secrets_encryption = true
   ```

2. **Enable automatic key rotation**
   ```hcl
   kms_enable_key_rotation = true
   ```

3. **Use a reasonable deletion window**
   ```hcl
   kms_key_deletion_window = 30  # Allows recovery if deleted accidentally
   ```

4. **Monitor KMS key usage**
   ```bash
   # Enable CloudTrail for KMS events
   aws cloudtrail create-trail \
     --name eks-kms-audit \
     --s3-bucket-name my-audit-bucket
   ```

5. **Set up CloudWatch alarms for key usage**
   ```bash
   # Alert on unauthorized key access attempts
   aws cloudwatch put-metric-alarm \
     --alarm-name eks-kms-unauthorized-access \
     --metric-name UserErrorCount \
     --namespace AWS/KMS
   ```

### ❌ DON'T

1. **Don't disable encryption in production**
   ```hcl
   enable_secrets_encryption = false  # ❌ Only for dev/test
   ```

2. **Don't use short deletion windows in production**
   ```hcl
   kms_key_deletion_window = 7  # ❌ Too short for production
   ```

3. **Don't share KMS keys across environments**
   - Separate keys for dev/staging/prod
   - Prevents cross-environment access

4. **Don't delete KMS keys manually**
   - Use `terraform destroy` instead
   - Respects deletion window

---

## Cost Analysis

### KMS Key Costs

**Customer Managed Key (CMK):**
- $1.00/month per key
- $0.03 per 10,000 API requests

**Estimated Monthly Cost (typical cluster):**
```
KMS Key:        $1.00/month
API Requests:   $0.30/month (10,000 requests)
-----------------------------------------
Total:          ~$1.30/month
```

**AWS-Managed Key:**
- Free (no monthly charge)
- API requests included
- Limited control and visibility

**Recommendation:** The ~$1.30/month cost for CMK is worth it for:
- Production environments
- Compliance requirements
- Security audit trails

---

## Deployment Examples

### Example 1: New Cluster with Envelope Encryption

```hcl
# terraform.tfvars
cluster_name = "prod-eks-cluster"
vpc_id = "vpc-0123456789abcdef0"
aws_region = "us-east-1"

# Enable envelope encryption with auto-created key
enable_secrets_encryption = true
kms_key_arn = ""
kms_enable_key_rotation = true
kms_key_deletion_window = 30

tags = {
  Environment = "production"
  Compliance  = "PCI-DSS"
}
```

**Deploy:**
```bash
terraform init
terraform plan
# Review: Should show KMS key creation
terraform apply
```

---

### Example 2: Use Existing Centralized KMS Key

```hcl
# terraform.tfvars
cluster_name = "dev-eks-cluster"
vpc_id = "vpc-0123456789abcdef0"
aws_region = "us-east-1"

# Use existing organizational KMS key
enable_secrets_encryption = true
kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/existing-key-id"
```

---

### Example 3: Disable Encryption (Dev Only)

```hcl
# terraform.tfvars
cluster_name = "dev-eks-cluster"
vpc_id = "vpc-0123456789abcdef0"
aws_region = "us-east-1"

# Disable for development environment
enable_secrets_encryption = false
```

---

## Verification

### After Deployment

```bash
# Check if encryption is enabled
aws eks describe-cluster \
  --name <cluster-name> \
  --query 'cluster.encryptionConfig' \
  --output json

# Expected output:
{
  "resources": ["secrets"],
  "provider": {
    "keyArn": "arn:aws:kms:us-east-1:123456789012:key/xxxxx"
  }
}

# Get KMS key details
terraform output kms_key_arn
terraform output kms_key_alias

# Test encryption with a secret
kubectl create secret generic test-secret --from-literal=password=supersecret

# Verify secret exists (encrypted in etcd)
kubectl get secret test-secret

# Check KMS key usage in CloudTrail
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=ResourceName,AttributeValue=<kms-key-arn> \
  --max-results 10
```

---

## Rotating Encryption Keys

### Automatic Rotation (Recommended)

When `kms_enable_key_rotation = true`:
- KMS automatically rotates the key every 365 days
- Old key versions retained for decryption
- No action required from you
- Transparent to applications

### Manual Rotation (Advanced)

If you need to change to a different KMS key:

```bash
# 1. Create new secret with new key
aws eks update-cluster-config \
  --name <cluster-name> \
  --encryption-config '[{"resources":["secrets"],"provider":{"keyArn":"<new-key-arn>"}}]'

# 2. Re-encrypt all existing secrets
kubectl get secrets --all-namespaces -o json | kubectl replace -f -
```

---

## Troubleshooting

### Issue: KMS key access denied

**Error:**
```
Error: creating EKS Cluster: InvalidParameterException: 
The provided KMS key is not valid
```

**Solution:** Ensure key policy allows EKS:

```bash
# Get key policy
aws kms get-key-policy \
  --key-id <key-id> \
  --policy-name default \
  --output json

# Should include EKS service principal
```

---

### Issue: Cannot decrypt secrets

**Error:**
```
Failed to decrypt secret: AccessDeniedException
```

**Solution:** Check IRSA/node role permissions:

```bash
# Verify EKS can use the key
aws kms describe-key --key-id <key-arn>

# Check CloudTrail for denied requests
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=Decrypt
```

---

### Issue: High KMS API costs

**Solution:** Reduce secret read frequency:

```yaml
# Use environment variables instead of secrets for non-sensitive data
# Cache secrets in application memory
# Use fewer secret updates
```

---

## Migration Guide

### Enabling Encryption on Existing Cluster

⚠️ **Warning:** You cannot enable encryption on an existing cluster. You must:

1. Create a new cluster with encryption enabled
2. Migrate workloads to the new cluster
3. Decommission the old cluster

**Migration Steps:**

```bash
# 1. Create new cluster with encryption
enable_secrets_encryption = true

terraform apply -target=module.eks

# 2. Update kubeconfig
aws eks update-kubeconfig --name <new-cluster-name>

# 3. Migrate resources
kubectl get all -A --kubeconfig old-cluster.yaml -o yaml | \
  kubectl apply --kubeconfig new-cluster.yaml -f -

# 4. Verify migration
kubectl get all -A

# 5. Destroy old cluster
terraform destroy -target=module.old_eks
```

---

## Compliance Mapping

| Compliance Standard | Requirement | Blueprint Support |
|--------------------|-------------|-------------------|
| **PCI-DSS** | Encrypt cardholder data | ✅ CMK encryption |
| **HIPAA** | Encrypt PHI at rest | ✅ CMK encryption |
| **SOC 2** | Encryption key management | ✅ KMS + CloudTrail |
| **GDPR** | Data protection | ✅ Encryption + audit |
| **FedRAMP** | FIPS 140-2 validated | ✅ KMS is FIPS validated |
| **ISO 27001** | Cryptographic controls | ✅ CMK + rotation |

---

## Summary

### Recommended Configuration (Production)

```hcl
enable_secrets_encryption = true
kms_key_arn = ""  # Let Terraform create
kms_enable_key_rotation = true
kms_key_deletion_window = 30
```

**Benefits:**
- ✅ Secrets encrypted with customer-managed key
- ✅ Automatic key rotation
- ✅ Full audit trail via CloudTrail
- ✅ Compliance-ready
- ✅ Recoverable if key deleted accidentally

**Cost:** ~$1.30/month (negligible compared to security benefits)

---

## Quick Reference

```bash
# Check encryption status
terraform output secrets_encryption_enabled

# Get KMS key ARN
terraform output kms_key_arn

# View key details
aws kms describe-key --key-id $(terraform output -raw kms_key_arn)

# List key grants
aws kms list-grants --key-id $(terraform output -raw kms_key_id)

# View CloudTrail logs for key
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=ResourceName,AttributeValue=$(terraform output -raw kms_key_arn)
```

---

**Recommendation:** Always enable envelope encryption for production EKS clusters! 🔒
