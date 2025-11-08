# IAM Permissions Required for Deployment

This document outlines the IAM permissions required for a build server or CI/CD pipeline to deploy this EKS Auto Mode Terraform blueprint.

## Overview

When deploying from a build server, the IAM role attached to the build server (or the IAM user/role assumed by the CI/CD pipeline) needs permissions to create and manage the following AWS resources:

- EKS Cluster and related resources
- IAM Roles and Policies
- EC2 resources (for EKS nodes)
- VPC-related resources (read-only, since VPC exists)
- Kubernetes resources via kubectl provider

## Required IAM Permissions

### Option 1: Managed Policies (Simplest Approach)

Attach these AWS managed policies to your build server's IAM role:

```json
{
  "ManagedPolicies": [
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSServicePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/IAMFullAccess"
  ]
}
```

**Pros:** Quick to set up, comprehensive coverage  
**Cons:** Broader permissions than minimally required (not least privilege)

---

### Option 2: Custom Least Privilege Policy (Recommended for Production)

Create a custom IAM policy with minimal required permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EKSClusterManagement",
      "Effect": "Allow",
      "Action": [
        "eks:CreateCluster",
        "eks:DeleteCluster",
        "eks:DescribeCluster",
        "eks:UpdateClusterConfig",
        "eks:UpdateClusterVersion",
        "eks:ListClusters",
        "eks:TagResource",
        "eks:UntagResource",
        "eks:CreateAccessEntry",
        "eks:DeleteAccessEntry",
        "eks:DescribeAccessEntry",
        "eks:ListAccessEntries",
        "eks:AssociateAccessPolicy",
        "eks:DisassociateAccessPolicy",
        "eks:ListAccessPolicies",
        "eks:UpdateAccessEntry",
        "eks:CreateAddon",
        "eks:DeleteAddon",
        "eks:DescribeAddon",
        "eks:ListAddons",
        "eks:UpdateAddon"
      ],
      "Resource": "*"
    },
    {
      "Sid": "IAMRoleManagement",
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:GetRole",
        "iam:ListRoles",
        "iam:ListRolePolicies",
        "iam:ListAttachedRolePolicies",
        "iam:ListInstanceProfilesForRole",
        "iam:TagRole",
        "iam:UntagRole",
        "iam:UpdateRole",
        "iam:UpdateRoleDescription",
        "iam:UpdateAssumeRolePolicy",
        "iam:PassRole"
      ],
      "Resource": [
        "arn:aws:iam::*:role/*EKS*",
        "arn:aws:iam::*:role/*eks*",
        "arn:aws:iam::*:role/*AmazonEKS*"
      ]
    },
    {
      "Sid": "IAMPolicyManagement",
      "Effect": "Allow",
      "Action": [
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:CreatePolicy",
        "iam:DeletePolicy",
        "iam:GetPolicy",
        "iam:GetPolicyVersion",
        "iam:ListPolicyVersions"
      ],
      "Resource": "*"
    },
    {
      "Sid": "EC2NetworkingRead",
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeVpcs",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeAvailabilityZones",
        "ec2:DescribeAccountAttributes",
        "ec2:DescribeInternetGateways",
        "ec2:DescribeRouteTables",
        "ec2:DescribeNatGateways"
      ],
      "Resource": "*"
    },
    {
      "Sid": "EC2SecurityGroupManagement",
      "Effect": "Allow",
      "Action": [
        "ec2:CreateSecurityGroup",
        "ec2:DeleteSecurityGroup",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:AuthorizeSecurityGroupEgress",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupEgress",
        "ec2:CreateTags",
        "ec2:DeleteTags"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "aws:RequestTag/kubernetes.io/cluster/*": "*"
        }
      }
    },
    {
      "Sid": "EC2LaunchTemplateManagement",
      "Effect": "Allow",
      "Action": [
        "ec2:CreateLaunchTemplate",
        "ec2:DeleteLaunchTemplate",
        "ec2:DescribeLaunchTemplates",
        "ec2:DescribeLaunchTemplateVersions",
        "ec2:CreateLaunchTemplateVersion"
      ],
      "Resource": "*"
    },
    {
      "Sid": "CloudWatchLogsManagement",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:DeleteLogGroup",
        "logs:DescribeLogGroups",
        "logs:ListTagsLogGroup",
        "logs:PutRetentionPolicy",
        "logs:TagLogGroup",
        "logs:UntagLogGroup"
      ],
      "Resource": "arn:aws:logs:*:*:log-group:/aws/eks/*"
    },
    {
      "Sid": "OIDCProviderManagement",
      "Effect": "Allow",
      "Action": [
        "iam:CreateOpenIDConnectProvider",
        "iam:DeleteOpenIDConnectProvider",
        "iam:GetOpenIDConnectProvider",
        "iam:ListOpenIDConnectProviders",
        "iam:TagOpenIDConnectProvider",
        "iam:UntagOpenIDConnectProvider"
      ],
      "Resource": "*"
    },
    {
      "Sid": "STSGetCallerIdentity",
      "Effect": "Allow",
      "Action": [
        "sts:GetCallerIdentity"
      ],
      "Resource": "*"
    },
    {
      "Sid": "KMSForEKS",
      "Effect": "Allow",
      "Action": [
        "kms:CreateGrant",
        "kms:DescribeKey"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "kms:ViaService": [
            "eks.*.amazonaws.com"
          ]
        }
      }
    }
  ]
}
```

---

### Option 3: Terraform Cloud/Enterprise (Recommended for Teams)

If using Terraform Cloud or Terraform Enterprise, create a dedicated service role with the above permissions and configure dynamic credentials.

---

## Additional Permissions for kubectl Provider

The blueprint uses the `kubectl` provider to deploy Kubernetes manifests. The IAM role needs permissions to interact with the EKS cluster's Kubernetes API:

**This is automatically handled through:**
1. The IAM role's ability to call `eks:DescribeCluster`
2. The `enable_cluster_creator_admin_permissions = true` setting in the blueprint
3. The AWS CLI's `eks get-token` command

**No additional permissions needed** - the kubectl provider authenticates using the AWS IAM role.

---

## Trust Policy for Build Server Role

Your build server's IAM role needs a trust policy allowing the service to assume it:

### For EC2 Build Server:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

### For AWS CodeBuild:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

### For GitHub Actions (OIDC):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR_ORG/YOUR_REPO:*"
        }
      }
    }
  ]
}
```

---

## Terraform Backend Permissions (Optional)

If using S3 backend for Terraform state (recommended for production):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "S3StateManagement",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::YOUR-TERRAFORM-STATE-BUCKET",
        "arn:aws:s3:::YOUR-TERRAFORM-STATE-BUCKET/*"
      ]
    },
    {
      "Sid": "DynamoDBStateLocking",
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem",
        "dynamodb:DescribeTable"
      ],
      "Resource": "arn:aws:dynamodb:*:*:table/YOUR-TERRAFORM-LOCK-TABLE"
    }
  ]
}
```

---

## Resource Tagging Requirements

The IAM role needs permissions to tag resources. Ensure these actions are included:

- `ec2:CreateTags` / `ec2:DeleteTags`
- `eks:TagResource` / `eks:UntagResource`
- `iam:TagRole` / `iam:UntagRole`
- `logs:TagLogGroup` / `logs:UntagLogGroup`

---

## Permissions NOT Required

Since this blueprint uses an **existing VPC**, the following permissions are **NOT needed**:

- ❌ VPC creation (`ec2:CreateVpc`)
- ❌ Subnet creation (`ec2:CreateSubnet`)
- ❌ Internet Gateway creation (`ec2:CreateInternetGateway`)
- ❌ NAT Gateway creation (`ec2:CreateNatGateway`)
- ❌ Route table creation (`ec2:CreateRouteTable`)

---

## Setup Instructions

### Step 1: Create IAM Policy

```bash
# Save the custom policy to a file
cat > eks-deployment-policy.json << 'EOF'
{
  # Paste the custom policy JSON from Option 2 above
}
EOF

# Create the policy
aws iam create-policy \
  --policy-name EKS-AutoMode-Deployment-Policy \
  --policy-document file://eks-deployment-policy.json
```

### Step 2: Create IAM Role

```bash
# Create trust policy
cat > trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Create the role
aws iam create-role \
  --role-name EKS-AutoMode-Deployment-Role \
  --assume-role-policy-document file://trust-policy.json
```

### Step 3: Attach Policy to Role

```bash
# Get your AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Attach the policy
aws iam attach-role-policy \
  --role-name EKS-AutoMode-Deployment-Role \
  --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/EKS-AutoMode-Deployment-Policy
```

### Step 4: Attach Role to Build Server

```bash
# For EC2 build server - create instance profile
aws iam create-instance-profile \
  --instance-profile-name EKS-AutoMode-Deployment-Profile

aws iam add-role-to-instance-profile \
  --instance-profile-name EKS-AutoMode-Deployment-Profile \
  --role-name EKS-AutoMode-Deployment-Role

# Attach to EC2 instance
aws ec2 associate-iam-instance-profile \
  --instance-id i-1234567890abcdef0 \
  --iam-instance-profile Name=EKS-AutoMode-Deployment-Profile
```

---

## Verification

After setting up the IAM role, verify permissions:

```bash
# Assume the role (if testing from CLI)
aws sts assume-role \
  --role-arn arn:aws:iam::ACCOUNT_ID:role/EKS-AutoMode-Deployment-Role \
  --role-session-name terraform-deployment

# Test EKS permissions
aws eks list-clusters

# Test IAM permissions
aws iam get-role --role-name EKS-AutoMode-Deployment-Role

# Test EC2 permissions
aws ec2 describe-vpcs
```

---

## CI/CD Pipeline Example

### GitHub Actions Example

```yaml
name: Deploy EKS Auto Mode
on:
  push:
    branches: [main]

permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          role-to-assume: arn:aws:iam::ACCOUNT_ID:role/EKS-AutoMode-Deployment-Role
          aws-region: us-east-1
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
      
      - name: Terraform Init
        run: terraform init
        working-directory: ./terraform-eks
      
      - name: Terraform Plan
        run: terraform plan
        working-directory: ./terraform-eks
      
      - name: Terraform Apply
        run: terraform apply -auto-approve
        working-directory: ./terraform-eks
```

---

## Security Best Practices

### 1. Use Least Privilege
- Start with minimal permissions (Option 2)
- Add permissions only when needed
- Regularly audit and remove unused permissions

### 2. Enable MFA for Sensitive Operations
```json
{
  "Condition": {
    "Bool": {
      "aws:MultiFactorAuthPresent": "true"
    }
  }
}
```

### 3. Restrict to Specific Regions (Optional)
```json
{
  "Condition": {
    "StringEquals": {
      "aws:RequestedRegion": ["us-east-1", "us-west-2"]
    }
  }
}
```

### 4. Use Resource Tags for Access Control
```json
{
  "Condition": {
    "StringEquals": {
      "aws:ResourceTag/ManagedBy": "Terraform"
    }
  }
}
```

### 5. Enable CloudTrail Logging
Monitor all API calls made by the deployment role.

---

## Troubleshooting Permission Issues

### Common Errors:

**Error:** `AccessDenied: User: arn:aws:iam::xxx:role/xxx is not authorized to perform: eks:CreateCluster`

**Solution:** Add `eks:CreateCluster` permission to the IAM policy

---

**Error:** `AccessDenied: User: arn:aws:iam::xxx:role/xxx is not authorized to perform: iam:PassRole`

**Solution:** Add `iam:PassRole` permission with appropriate resource constraints

---

**Error:** `AccessDenied: User: arn:aws:iam::xxx:role/xxx is not authorized to perform: ec2:DescribeVpcs`

**Solution:** Add VPC read permissions (already included in the policy above)

---

## Summary

For a build server deploying this EKS Auto Mode blueprint:

**Minimum Required Permissions:**
- ✅ EKS cluster management
- ✅ IAM role/policy management
- ✅ EC2 security group management
- ✅ VPC resource read access
- ✅ CloudWatch Logs management
- ✅ OIDC provider management

**NOT Required (since VPC exists):**
- ❌ VPC/Subnet creation
- ❌ NAT Gateway creation
- ❌ Internet Gateway creation

**Recommended Approach:**
1. Use **Option 2** (Custom Least Privilege Policy) for production
2. Test in dev environment first
3. Add S3/DynamoDB permissions if using remote state
4. Enable CloudTrail for audit logging
5. Use role assumption with MFA for sensitive operations

---

**File Location:** This document should be referenced before setting up CI/CD pipelines or build servers for automated deployments.
