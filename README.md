# AWS EKS Auto Mode Terraform Blueprint

A production-ready, reusable Terraform blueprint for deploying Amazon EKS clusters with Auto Mode across any client environment. This blueprint assumes an existing VPC and provides flexible configuration for custom node pools, storage classes, and ingress classes.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Customization](#customization)
- [Usage Examples](#usage-examples)
- [Validation](#validation)
- [Cleanup](#cleanup)
- [Troubleshooting](#troubleshooting)
- [Security Considerations](#security-considerations)
- [Contributing](#contributing)

## Overview

This blueprint deploys an Amazon EKS cluster with Auto Mode enabled, which provides fully managed compute capacity with automatic node provisioning and lifecycle management. The blueprint is designed to work with existing VPC infrastructure and can be easily customized for different client environments.

### What is EKS Auto Mode?

EKS Auto Mode is a feature that provides:
- **Automatic Node Provisioning**: Automatically provisions the right compute capacity based on workload requirements
- **Managed Infrastructure**: AWS manages the underlying compute infrastructure, including patching and updates
- **Cost Optimization**: Optimizes costs by automatically selecting the most appropriate instance types
- **Custom Node Pools**: Allows fine-grained control over compute options for different workload types

## Features

### Core Features
- ✅ **Existing VPC Integration**: Works with pre-existing VPC infrastructure
- ✅ **EKS Auto Mode**: Fully managed compute with automatic node provisioning
- ✅ **Custom Node Pools**: Pre-configured AMD64 and Graviton (ARM64) node pools
- ✅ **Custom Node Classes**: Multiple NodeClass configurations (basic, EBS-optimized)
- ✅ **EBS Storage Class**: Automatic EBS volume provisioning with encryption
- ✅ **ALB Ingress Class**: Application Load Balancer integration (public & internal)
- ✅ **Flexible Configuration**: Extensive variable-based customization
- ✅ **Multi-Environment Support**: Easy configuration for different client environments

### Security & Compliance Features
- ✅ **KMS Envelope Encryption**: Customer-managed keys for Kubernetes secrets (enabled by default)
- ✅ **Control Plane Logging**: CloudWatch Logs integration for audit, API, authenticator logs
- ✅ **Additional Security Groups**: Configurable ingress rules for cluster access control
- ✅ **Private Endpoints**: Support for fully private cluster endpoints
- ✅ **Cluster Deletion Protection**: Prevents accidental cluster deletion (enabled by default)
- ✅ **IAM Roles for Service Accounts (IRSA)**: Pod-level AWS permissions

### High Availability & Resilience
- ✅ **ARC Zonal Shift**: Automatic traffic shifting from impaired Availability Zones (enabled by default)
- ✅ **Multi-AZ Deployment**: Spreads workloads across multiple Availability Zones
- ✅ **EKS Upgrade Policy**: STANDARD (14 months) or EXTENDED (26 months) support options

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Existing VPC                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              Private Subnets                         │   │
│  │  ┌────────────────────────────────────────────┐     │   │
│  │  │         EKS Auto Mode Cluster              │     │   │
│  │  │                                             │     │   │
│  │  │  ┌──────────────┐  ┌──────────────┐        │     │   │
│  │  │  │  AMD64 Pool  │  │ Graviton Pool│        │     │   │
│  │  │  │ (x86_64)     │  │   (ARM64)    │        │     │   │
│  │  │  └──────────────┘  └──────────────┘        │     │   │
│  │  │                                             │     │   │
│  │  │  Auto-managed by Karpenter                  │     │   │
│  │  └────────────────────────────────────────────┘     │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘

         ↓                          ↓
    ┌─────────┐              ┌──────────┐
    │   EBS   │              │   ALB    │
    │ Volumes │              │(Ingress) │
    └─────────┘              └──────────┘
```

## Prerequisites

Before using this blueprint, ensure you have:

### Required Tools
- **Terraform** >= 1.3
- **AWS CLI** >= 2.0
- **kubectl** >= 1.29
- **Valid AWS credentials** with appropriate permissions

### AWS Resources
- **Existing VPC** with:
  - At least 2 private subnets across different availability zones
  - Proper subnet tagging for Kubernetes (see [VPC Requirements](#vpc-requirements))
  - NAT Gateway for private subnet internet access
  - DNS hostnames and DNS resolution enabled

### IAM Permissions
The AWS credentials used must have permissions to:
- Create and manage EKS clusters
- Create and manage IAM roles and policies
- Create and manage EC2 instances and security groups
- Access VPC and subnet resources

## Quick Start

### 1. Clone or Copy the Blueprint

```bash
cd terraform-eks
```

### 2. Configure for Your Environment

```bash
# Copy the example tfvars file
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your configuration
notepad terraform.tfvars
```

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Review the Planned Changes

```bash
terraform plan
```

### 5. Deploy the Cluster

```bash
terraform apply
```

### 6. Configure kubectl

After successful deployment, configure kubectl to access your cluster:

```bash
aws eks update-kubeconfig --region <your-region> --name <cluster-name>
```

Or use the output from Terraform:

```bash
# The command is displayed in the Terraform output
terraform output -raw configure_kubectl
```

### 7. Verify the Cluster

```bash
kubectl get nodes
kubectl get nodepools
kubectl get nodeclasses
```

## Configuration

### VPC Requirements

Your existing VPC must have private subnets properly tagged. The blueprint uses tags to identify subnets:

```hcl
# Example subnet tags
tags = {
  "kubernetes.io/role/internal-elb" = "1"
  # Or custom tags like:
  "Tier" = "Private"
}
```

Update the `private_subnet_tags` variable to match your subnet tagging strategy:

```hcl
private_subnet_tags = {
  "kubernetes.io/role/internal-elb" = "1"
}
```

### Required Variables

The following variables **must** be set in your `terraform.tfvars`:

```hcl
# Required
cluster_name = "my-eks-cluster"
vpc_id       = "vpc-0123456789abcdef0"

# Recommended
aws_region = "us-east-1"
tags = {
  Environment = "production"
  Project     = "my-project"
}
```

### Optional Variables

See `variables.tf` for a complete list of configurable options. Key optional variables include:

- `cluster_version`: Kubernetes version (default: "1.31")
- `enable_default_node_pools`: Enable default Auto Mode node pools (default: false)
- `cluster_endpoint_public_access`: Enable public API endpoint (default: false)
- `additional_node_iam_policies`: Additional IAM policies for node role

## Customization

### Adding Custom Node Pools

1. Create a new YAML file in `eks-automode-config/`:

```yaml
# eks-automode-config/nodepool-gpu.yaml
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: gpu
spec:
  template:
    metadata:
      labels:
        type: karpenter
        provisioner: gpu
        NodeGroupType: GPU
    spec:
      taints:
        - key: nvidia.com/gpu
          effect: NoSchedule
      requirements:
        - key: "karpenter.sh/capacity-type"
          operator: In
          values: ["on-demand"]
        - key: "node.kubernetes.io/instance-type"
          operator: In
          values: ["p3.2xlarge", "p3.8xlarge", "g4dn.xlarge"]
      nodeClassRef:
        name: ebs-optimized
        group: eks.amazonaws.com
        kind: NodeClass
  limits:
    cpu: 500
```

2. Update `terraform.tfvars`:

```hcl
custom_nodepool_yamls = [
  "nodepool-amd64.yaml",
  "nodepool-graviton.yaml",
  "nodepool-gpu.yaml"
]
```

### Adding Custom Node Classes

1. Create a new YAML file in `eks-automode-config/`:

```yaml
# eks-automode-config/nodeclass-gpu.yaml
apiVersion: eks.amazonaws.com/v1
kind: NodeClass
metadata:
  name: gpu
spec:
  role: "${node_iam_role_name}"
  subnetSelectorTerms:
    - tags:
        Name: "${cluster_name}-private*"
  securityGroupSelectorTerms:
    - tags:
        Name: "${cluster_name}-node"
  ephemeralStorage:
    size: "200Gi"
    iops: 10000
    throughput: 500
  tags:
    Environment: "production"
    Team: "ml-team"
```

2. Update `terraform.tfvars`:

```hcl
custom_nodeclass_yamls = [
  "nodeclass-basic.yaml",
  "nodeclass-ebs-optimized.yaml",
  "nodeclass-gpu.yaml"
]
```

### Modifying Storage Classes

Edit `eks-automode-config/ebs-storageclass.yaml`:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: auto-ebs-sc
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: ebs.csi.eks.amazonaws.com
volumeBindingMode: WaitForFirstConsumer
parameters:
  type: gp3
  encrypted: "true"
  iops: "3000"
  throughput: "125"
```

## Usage Examples

### Deploying a Workload with Node Pool Selection

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  namespace: default
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      # Select the AMD64 node pool
      nodeSelector:
        NodeGroupType: amd64
      # Tolerate the AMD64 taint
      tolerations:
        - key: amd64
          effect: NoSchedule
      containers:
        - name: my-app
          image: nginx:latest
          ports:
            - containerPort: 80
```

### Deploying a Graviton (ARM64) Workload

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: arm-app
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: arm-app
  template:
    metadata:
      labels:
        app: arm-app
    spec:
      # Select the Graviton node pool
      nodeSelector:
        NodeGroupType: Graviton
      # Tolerate the Graviton taint
      tolerations:
        - key: graviton
          effect: NoSchedule
      containers:
        - name: arm-app
          image: nginx:latest  # Ensure your image supports ARM64
          ports:
            - containerPort: 80
```

### Using EBS Persistent Volumes

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-data
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: auto-ebs-sc
  resources:
    requests:
      storage: 10Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: app-with-storage
spec:
  containers:
    - name: app
      image: nginx
      volumeMounts:
        - name: data
          mountPath: /data
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: my-data
```

### Creating an ALB Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
spec:
  ingressClassName: alb
  rules:
    - host: myapp.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-service
                port:
                  number: 80
```

## Validation

### Check Cluster Status

```bash
# Get cluster info
kubectl cluster-info

# Check nodes
kubectl get nodes -o wide

# View node pools
kubectl get nodepools

# View node classes
kubectl get nodeclasses -n kube-system
```

### Verify Auto Mode Components

```bash
# Check if nodes are being provisioned
kubectl get nodes -l type=karpenter

# View storage classes
kubectl get storageclass

# View ingress classes
kubectl get ingressclass
```

### Test Node Provisioning

Deploy a test workload to verify node provisioning:

```bash
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-deployment
spec:
  replicas: 2
  selector:
    matchLabels:
      app: test
  template:
    metadata:
      labels:
        app: test
    spec:
      nodeSelector:
        NodeGroupType: amd64
      tolerations:
        - key: amd64
          effect: NoSchedule
      containers:
        - name: nginx
          image: nginx:latest
          resources:
            requests:
              cpu: "1"
              memory: "1Gi"
EOF

# Watch nodes being provisioned
kubectl get nodes -w
```

## Cleanup

### Remove Test Workloads

```bash
kubectl delete deployment test-deployment
```

### Destroy Infrastructure

```bash
# Remove all Kubernetes resources first
kubectl delete all --all --all-namespaces

# Wait for resources to be cleaned up (especially LoadBalancers)
sleep 60

# Destroy Terraform-managed infrastructure
terraform destroy
```

**Important**: Ensure all LoadBalancers and EBS volumes created by Kubernetes are deleted before running `terraform destroy`, or they may prevent the VPC from being properly cleaned up.

## Troubleshooting

### Nodes Not Provisioning

If nodes are not being provisioned automatically:

1. Check NodePool status:
   ```bash
   kubectl describe nodepool amd64
   kubectl describe nodepool graviton
   ```

2. Verify NodeClass configuration:
   ```bash
   kubectl get nodeclass -A
   kubectl describe nodeclass ebs-optimized
   ```

3. Check for subnet/security group tagging issues:
   ```bash
   aws ec2 describe-subnets --subnet-ids <subnet-id>
   ```

### kubectl Connection Issues

If you can't connect to the cluster:

1. Update kubeconfig:
   ```bash
   aws eks update-kubeconfig --region <region> --name <cluster-name>
   ```

2. Verify AWS credentials:
   ```bash
   aws sts get-caller-identity
   ```

3. Check cluster endpoint access settings in `variables.tf`

### Permission Errors

If you encounter IAM permission errors:

1. Verify the custom node role has necessary policies attached
2. Check cluster access entries
3. Ensure your AWS credentials have sufficient permissions

## Security Considerations

### Network Security
- **Private Endpoints**: By default, the cluster endpoint is private-only
- **Security Groups**: Automatically configured by the EKS module
- **Subnet Isolation**: Uses private subnets for worker nodes

### Data Security
- **Encryption at Rest**: EBS volumes are encrypted by default
- **Encryption in Transit**: All Kubernetes API communication is encrypted
- **Secrets Management**: Use AWS Secrets Manager or Parameter Store for sensitive data

### Access Control
- **RBAC**: Kubernetes RBAC is enabled by default
- **IAM Roles**: Uses IAM roles for service accounts (IRSA)
- **Cluster Access**: Managed through EKS access entries

### Best Practices
1. **Disable public endpoint access** for production environments
2. **Use VPN or bastion host** for cluster access
3. **Regularly update** Kubernetes versions
4. **Enable audit logging** for compliance
5. **Implement network policies** for pod-to-pod communication
6. **Use separate IAM roles** for different workload types

## Multi-Environment Setup

### Development Environment

```hcl
# terraform.tfvars
cluster_name                    = "dev-eks-cluster"
cluster_endpoint_public_access  = true  # For easier access during development
enable_default_node_pools       = false
tags = {
  Environment = "development"
}
```

### Production Environment

```hcl
# terraform.tfvars
cluster_name                    = "prod-eks-cluster"
cluster_endpoint_public_access  = false  # Private only
cluster_endpoint_private_access = true
enable_default_node_pools       = false
tags = {
  Environment = "production"
  Compliance  = "required"
}
```

## Additional Resources

### AWS Documentation
- [EKS Auto Mode Documentation](https://docs.aws.amazon.com/eks/latest/userguide/automode.html)
- [EKS Control Plane Logging](https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html)
- [EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)
- [Karpenter Documentation](https://karpenter.sh/)
- [Terraform AWS EKS Module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest)

### Blueprint Documentation
- [Control Plane Logging Guide](docs/CONTROL_PLANE_LOGGING.md) - CloudWatch Logs configuration
- [Additional Security Group](docs/ADDITIONAL_SECURITY_GROUP.md) - Custom security group setup
- [Secrets Encryption](docs/SECRETS_ENCRYPTION.md) - KMS envelope encryption for secrets
- [ARC Zonal Shift](docs/ARC_ZONAL_SHIFT.md) - High availability configuration
- [VPC Endpoint Requirements](docs/VPC_ENDPOINT_REQUIREMENTS.md) - Private cluster requirements
- [IAM Permissions](docs/IAM_PERMISSIONS.md) - Required IAM policies
- [Terraform Templating](docs/TERRAFORM_TEMPLATING.md) - How templatefile() works
- [ALB IngressClass Usage](docs/ALB_INGRESSCLASS_USAGE.md) - Public vs internal ALB

## Contributing

This blueprint is designed to be a starting point for your EKS deployments. Feel free to customize and extend it based on your specific requirements.

## License

This blueprint is provided as-is for reference purposes. Modify as needed for your organization's requirements.

---

**Note**: This blueprint creates billable AWS resources. Always review the Terraform plan before applying and clean up resources when no longer needed.
