# VPC Endpoint Requirements for Fully Private EKS Cluster

## Overview

For **fully private EKS clusters** (no internet access), your existing VPC **must have specific VPC endpoints** configured. Without these endpoints, the cluster cannot:
- Pull container images from ECR
- Register nodes to the cluster
- Send logs to CloudWatch
- Provision load balancers
- Scale nodes

## Prerequisites Check

Before deploying this blueprint to a client environment, verify the existing VPC has the following endpoints:

### 1. Gateway Endpoints (Route Table Based)

```bash
# Check for S3 gateway endpoint
aws ec2 describe-vpc-endpoints \
  --filters "Name=vpc-id,Values=<VPC_ID>" "Name=service-name,Values=com.amazonaws.<region>.s3" \
  --query 'VpcEndpoints[*].[VpcEndpointId,ServiceName,State]' \
  --output table
```

**Required:**
- ✅ `com.amazonaws.<region>.s3` - For ECR image layers stored in S3

### 2. Interface Endpoints (Private DNS Enabled)

```bash
# Check for required interface endpoints
aws ec2 describe-vpc-endpoints \
  --filters "Name=vpc-id,Values=<VPC_ID>" \
  --query 'VpcEndpoints[?ServiceName!=`com.amazonaws.<region>.s3`].[VpcEndpointId,ServiceName,State,PrivateDnsEnabled]' \
  --output table
```

**Required for EKS Auto Mode:**

| Endpoint | Purpose | Critical? |
|----------|---------|-----------|
| `ecr.api` | ECR authentication and registry operations | ✅ **CRITICAL** |
| `ecr.dkr` | Docker image pull operations | ✅ **CRITICAL** |
| `ec2` | EC2 API calls for node provisioning | ✅ **CRITICAL** |
| `sts` | IAM role assumption (IRSA, node roles) | ✅ **CRITICAL** |
| `logs` | CloudWatch Logs for cluster/pod logs | ✅ **CRITICAL** |
| `elasticloadbalancing` | ALB/NLB provisioning for Ingress | ✅ **CRITICAL** |
| `autoscaling` | EKS Auto Mode node scaling | ✅ **CRITICAL** |

**Recommended for Operational Excellence:**

| Endpoint | Purpose | Recommended? |
|----------|---------|--------------|
| `ssm` | Systems Manager for troubleshooting | ⭐ Highly Recommended |
| `ssmmessages` | SSM Session Manager connectivity | ⭐ Highly Recommended |
| `ec2messages` | SSM Session Manager connectivity | ⭐ Highly Recommended |
| `kms` | Customer-managed encryption keys | ⚠️ If using CMK |

### 3. VPC Endpoint Configuration Requirements

All interface endpoints **must have**:
- ✅ **Private DNS Enabled**: `PrivateDnsEnabled: true`
- ✅ **Subnet Coverage**: Deployed in same subnets as EKS nodes
- ✅ **Security Group**: Allow HTTPS (443) from VPC CIDR

Example security group rule:
```hcl
ingress {
  description = "HTTPS from VPC"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = [data.aws_vpc.existing.cidr_block]
}
```

## Deployment Scenarios

### Scenario A: Existing VPC Has All Endpoints ✅

**No changes needed** - Deploy blueprint as-is:
```bash
terraform init
terraform plan
terraform apply
```

### Scenario B: Existing VPC Missing Endpoints ⚠️

**Option 1: Request VPC Owner to Add Endpoints (Recommended)**

Provide them this reference configuration:

```hcl
module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "~> 5.1"

  vpc_id = var.vpc_id

  # Security group for endpoints
  create_security_group      = true
  security_group_name_prefix = "${var.cluster_name}-vpc-endpoints-"
  security_group_description = "VPC endpoint security group for EKS"
  
  security_group_rules = {
    ingress_https = {
      description = "HTTPS from VPC"
      cidr_blocks = [data.aws_vpc.existing.cidr_block]
    }
  }

  endpoints = merge(
    {
      s3 = {
        service         = "s3"
        service_type    = "Gateway"
        route_table_ids = <PRIVATE_ROUTE_TABLE_IDS>
        tags            = { Name = "${var.cluster_name}-s3" }
      }
    },
    { 
      for service in toset([
        "autoscaling", "ecr.api", "ecr.dkr", "ec2", "ec2messages",
        "elasticloadbalancing", "sts", "kms", "logs", "ssm", "ssmmessages"
      ]) :
      replace(service, ".", "_") => {
        service             = service
        subnet_ids          = data.aws_subnets.private.ids
        private_dns_enabled = true
        tags                = { Name = "${var.cluster_name}-${service}" }
      }
    }
  )

  tags = var.tags
}
```

**Option 2: Add Endpoints to This Blueprint**

If you manage the VPC, uncomment the VPC endpoints module in `main.tf` (see Optional Enhancement below).

### Scenario C: Hybrid - Public Endpoint for Kubectl Access

If you need to access the cluster from your laptop/CI-CD:

```hcl
# In terraform.tfvars
cluster_endpoint_public_access = true
cluster_endpoint_public_access_cidrs = [
  "203.0.113.0/24"  # Your office/VPN CIDR
]
```

**Note**: Nodes still communicate privately regardless of public endpoint setting.

## Testing Endpoint Connectivity

After cluster deployment, test from a node:

```bash
# Connect to a node via SSM Session Manager
aws ssm start-session --target <INSTANCE_ID>

# Test ECR access
nslookup <account_id>.dkr.ecr.<region>.amazonaws.com
# Should resolve to private IP (10.x.x.x or 172.x.x.x)

# Test S3 access
nslookup s3.<region>.amazonaws.com
# Should resolve to VPC endpoint IP

# Test from pod
kubectl run test-pod --image=amazonlinux:2023 -it --rm -- sh
nslookup <account_id>.dkr.ecr.<region>.amazonaws.com
```

## NAT Gateway Considerations

The AWS fully-private pattern **disables NAT Gateway** (`enable_nat_gateway = false`).

**Your blueprint assumes:**
- ❌ **No NAT Gateway** - Fully private (recommended for production)
- ✅ VPC endpoints handle all AWS service traffic

**If client VPC has NAT Gateway enabled:**
- Cluster will still work but incurs NAT costs
- Not truly "fully private" (can reach internet)
- Consider disabling NAT for production environments

## Container Image Strategy

**Private Clusters Require:**

1. **Option A: ECR Private Repository (Recommended)**
   ```bash
   # Push images to ECR in same region
   aws ecr get-login-password --region <region> | \
     docker login --username AWS --password-stdin <account>.dkr.ecr.<region>.amazonaws.com
   
   docker tag myapp:latest <account>.dkr.ecr.<region>.amazonaws.com/myapp:latest
   docker push <account>.dkr.ecr.<region>.amazonaws.com/myapp:latest
   ```

2. **Option B: ECR Pull-Through Cache**
   ```bash
   # Configure ECR pull-through cache for public images
   # See: https://docs.aws.amazon.com/AmazonECR/latest/userguide/pull-through-cache.html
   ```

3. **Option C: Self-Hosted Registry in VPC**
   - Deploy Harbor or similar in same VPC
   - Requires VPC endpoints for HA storage (S3)

**⚠️ Cannot use:** Direct pulls from Docker Hub, gcr.io, quay.io without pull-through cache or proxy

## Optional Enhancement: Add VPC Endpoint Validation

If you want the blueprint to **validate** VPC endpoints exist before deployment:

<function_calls>
<invoke name="file_search">
<parameter name="query">main.tf