# EKS Auto Mode Blueprint - Architecture Diagrams

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           AWS Cloud (Region)                             │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────┐   │
│  │                    Existing VPC (10.0.0.0/16)                   │   │
│  │                                                                  │   │
│  │  ┌──────────────────┐                  ┌──────────────────┐    │   │
│  │  │  Public Subnet   │                  │  Public Subnet   │    │   │
│  │  │   (AZ-1)         │                  │   (AZ-2)         │    │   │
│  │  │                  │                  │                  │    │   │
│  │  │  ┌────────────┐  │                  │  ┌────────────┐  │    │   │
│  │  │  │NAT Gateway │  │                  │  │NAT Gateway │  │    │   │
│  │  │  └────────────┘  │                  │  └────────────┘  │    │   │
│  │  └──────────────────┘                  └──────────────────┘    │   │
│  │           │                                      │              │   │
│  │  ┌────────▼──────────┐                  ┌───────▼─────────┐   │   │
│  │  │  Private Subnet   │                  │ Private Subnet  │   │   │
│  │  │   (AZ-1)          │                  │   (AZ-2)        │   │   │
│  │  │  10.0.0.0/20      │                  │  10.0.16.0/20   │   │   │
│  │  │                   │                  │                 │   │   │
│  │  │ ┌───────────────────────────────────────────────────┐ │   │   │
│  │  │ │         EKS Auto Mode Cluster                     │ │   │   │
│  │  │ │                                                   │ │   │   │
│  │  │ │  Control Plane (Managed by AWS)                  │ │   │   │
│  │  │ │  ┌─────────────────────────────────────────┐     │ │   │   │
│  │  │ │  │         Karpenter (Auto Mode)           │     │ │   │   │
│  │  │ │  └─────────────────────────────────────────┘     │ │   │   │
│  │  │ │                                                   │ │   │   │
│  │  │ │  Data Plane (Worker Nodes)                       │ │   │   │
│  │  │ │  ┌─────────────┐  ┌─────────────┐               │ │   │   │
│  │  │ │  │ AMD64 Pool  │  │Graviton Pool│               │ │   │   │
│  │  │ │  │  (x86_64)   │  │  (ARM64)    │               │ │   │   │
│  │  │ │  │             │  │             │               │ │   │   │
│  │  │ │  │  Node 1     │  │   Node 1    │               │ │   │   │
│  │  │ │  │  Node 2     │  │   Node 2    │               │ │   │   │
│  │  │ │  │  ...        │  │   ...       │               │ │   │   │
│  │  │ │  └─────────────┘  └─────────────┘               │ │   │   │
│  │  │ └───────────────────────────────────────────────────┘ │   │   │
│  │  └───────────────────┘                  └─────────────────┘   │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                    AWS Services (Managed)                     │  │
│  │  ┌─────────────┐  ┌──────────────┐  ┌──────────────┐        │  │
│  │  │ EBS Volumes │  │     ALB      │  │  CloudWatch  │        │  │
│  │  │ (Encrypted) │  │ (Ingress)    │  │  (Logging)   │        │  │
│  │  └─────────────┘  └──────────────┘  └──────────────┘        │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

## Node Pool Architecture

```
┌───────────────────────────────────────────────────────────────────┐
│                    EKS Auto Mode Cluster                          │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              Karpenter (Auto Mode Controller)            │    │
│  │  • Monitors pod scheduling needs                         │    │
│  │  • Provisions nodes automatically                        │    │
│  │  • Selects optimal instance types                        │    │
│  │  • Manages node lifecycle                                │    │
│  └─────────────────────────────────────────────────────────┘    │
│                              │                                    │
│              ┌───────────────┴───────────────┐                   │
│              │                               │                   │
│  ┌───────────▼─────────┐         ┌──────────▼──────────┐        │
│  │   AMD64 Node Pool   │         │ Graviton Node Pool  │        │
│  │   (x86_64 arch)     │         │   (ARM64 arch)      │        │
│  │                     │         │                     │        │
│  │ NodeClass:          │         │ NodeClass:          │        │
│  │  ebs-optimized      │         │  ebs-optimized      │        │
│  │                     │         │                     │        │
│  │ Instance Types:     │         │ Instance Types:     │        │
│  │  • c5.xlarge        │         │  • c6g.xlarge       │        │
│  │  • m5.2xlarge       │         │  • m6g.2xlarge      │        │
│  │  • r5.4xlarge       │         │  • r6g.4xlarge      │        │
│  │                     │         │                     │        │
│  │ Taints:             │         │ Taints:             │        │
│  │  key: amd64         │         │  key: graviton      │        │
│  │  effect: NoSchedule │         │  effect: NoSchedule │        │
│  │                     │         │                     │        │
│  │ Labels:             │         │ Labels:             │        │
│  │  NodeGroupType:     │         │  NodeGroupType:     │        │
│  │    amd64            │         │    Graviton         │        │
│  │                     │         │                     │        │
│  │ Limits:             │         │ Limits:             │        │
│  │  CPU: 1000 cores    │         │  CPU: 1000 cores    │        │
│  └─────────────────────┘         └─────────────────────┘        │
└───────────────────────────────────────────────────────────────────┘
```

## Workload Deployment Flow

```
┌──────────────────────────────────────────────────────────────────┐
│                    kubectl apply deployment                      │
└────────────────────────────┬─────────────────────────────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────────────┐
│              Kubernetes API Server (EKS Control Plane)           │
└────────────────────────────┬─────────────────────────────────────┘
                             │
                ┌────────────┴────────────┐
                │                         │
                ▼                         ▼
┌─────────────────────────┐   ┌─────────────────────────┐
│   Scheduler detects     │   │   Pod Spec includes:    │
│   pending pods          │   │   • nodeSelector        │
│                         │   │   • tolerations         │
└───────────┬─────────────┘   │   • resource requests   │
            │                 └─────────────────────────┘
            ▼
┌─────────────────────────────────────────────────────────┐
│         Karpenter (EKS Auto Mode Controller)            │
│  1. Evaluates pod requirements                          │
│  2. Matches to NodePool                                 │
│  3. Selects instance type from NodeClass                │
│  4. Provisions EC2 instance                             │
└───────────┬─────────────────────────────────────────────┘
            │
            ▼
┌─────────────────────────────────────────────────────────┐
│              New Node Provisioned                       │
│  • Joins cluster automatically                          │
│  • Has correct labels and taints                        │
│  • Uses IAM role from NodeClass                         │
│  • Attached to VPC subnets                              │
└───────────┬─────────────────────────────────────────────┘
            │
            ▼
┌─────────────────────────────────────────────────────────┐
│              Pod Scheduled to Node                      │
│  • Pod starts running                                   │
│  • Storage attached (if PVC)                            │
│  • Service endpoints updated                            │
└─────────────────────────────────────────────────────────┘
```

## Storage Provisioning Flow

```
┌──────────────────────────────────────────────────────────────────┐
│              kubectl apply -f pvc.yaml                           │
│              (PersistentVolumeClaim)                             │
└────────────────────────────┬─────────────────────────────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────────────┐
│                    Kubernetes API Server                         │
└────────────────────────────┬─────────────────────────────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────────────┐
│                EBS CSI Driver (Managed by AWS)                   │
│  • Detects PVC creation                                          │
│  • Reads StorageClass: auto-ebs-sc                               │
│  • Creates EBS volume with:                                      │
│    - Type: gp3                                                   │
│    - Encryption: enabled                                         │
│    - Size: as requested                                          │
└────────────────────────────┬─────────────────────────────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────────────┐
│                    AWS EBS Volume Created                        │
│  • Encrypted at rest                                             │
│  • Tagged with cluster info                                      │
│  • In same AZ as node                                            │
└────────────────────────────┬─────────────────────────────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────────────┐
│              Volume Attached to Node                             │
│  • Mounted to pod                                                │
│  • PVC status: Bound                                             │
│  • Pod can read/write data                                       │
└──────────────────────────────────────────────────────────────────┘
```

## Ingress/Load Balancer Flow

```
┌──────────────────────────────────────────────────────────────────┐
│              kubectl apply -f ingress.yaml                       │
└────────────────────────────┬─────────────────────────────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────────────┐
│                    Kubernetes API Server                         │
└────────────────────────────┬─────────────────────────────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────────────┐
│      AWS Load Balancer Controller (Managed by AWS)              │
│  • Detects Ingress creation                                      │
│  • Reads IngressClass: alb                                       │
│  • Reads IngressClassParams (scheme: internet-facing)            │
└────────────────────────────┬─────────────────────────────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────────────┐
│              Application Load Balancer Created                   │
│  • Provisioned in VPC                                            │
│  • Public subnets (internet-facing)                              │
│  • Security groups configured                                    │
│  • Target groups created                                         │
└────────────────────────────┬─────────────────────────────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────────────┐
│              Targets Registered                                  │
│  • Pod IPs registered as targets                                 │
│  • Health checks configured                                      │
│  • Traffic flows: Internet → ALB → Pods                          │
└──────────────────────────────────────────────────────────────────┘
```

## IAM Role Chain

```
┌──────────────────────────────────────────────────────────────────┐
│                    Terraform Execution                           │
│  Creates: custom_nodeclass_role                                  │
└────────────────────────────┬─────────────────────────────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────────────┐
│          IAM Role: <cluster-name>-AmazonEKSAutoNodeRole          │
│                                                                  │
│  Trust Policy:                                                   │
│  • Principal: ec2.amazonaws.com                                  │
│                                                                  │
│  Attached Policies:                                              │
│  • AmazonEKSWorkerNodeMinimalPolicy                              │
│  • AmazonEC2ContainerRegistryPullOnly                            │
│  • [Custom policies as needed]                                   │
└────────────────────────────┬─────────────────────────────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────────────┐
│                  EKS Access Entry Created                        │
│  • Type: EC2                                                     │
│  • Policy: AmazonEKSAutoNodePolicy                               │
│  • Scope: cluster                                                │
└────────────────────────────┬─────────────────────────────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────────────┐
│                NodeClass References Role                         │
│  spec:                                                           │
│    role: <cluster-name>-AmazonEKSAutoNodeRole                    │
└────────────────────────────┬─────────────────────────────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────────────┐
│              EC2 Instance Assumes Role                           │
│  • Instance profile attached                                     │
│  • Node can pull images from ECR                                 │
│  • Node can join cluster                                         │
│  • Node has minimal required permissions                         │
└──────────────────────────────────────────────────────────────────┘
```

## Multi-Environment Deployment Pattern

```
┌─────────────────────────────────────────────────────────────────┐
│                  Git Repository (Blueprint)                     │
│                                                                 │
│  terraform-eks/                                                 │
│  ├── main.tf                                                    │
│  ├── variables.tf                                               │
│  ├── outputs.tf                                                 │
│  └── ...                                                        │
└───────────────────────────┬─────────────────────────────────────┘
                            │
            ┌───────────────┼───────────────┐
            │               │               │
            ▼               ▼               ▼
┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐
│   Development    │ │     Staging      │ │   Production     │
│   Environment    │ │   Environment    │ │   Environment    │
│                  │ │                  │ │                  │
│ terraform.tfvars:│ │ terraform.tfvars:│ │ terraform.tfvars:│
│  cluster_name:   │ │  cluster_name:   │ │  cluster_name:   │
│   dev-eks        │ │   stg-eks        │ │   prd-eks        │
│  vpc_id:         │ │  vpc_id:         │ │  vpc_id:         │
│   vpc-dev-xxx    │ │   vpc-stg-xxx    │ │   vpc-prd-xxx    │
│  public_access:  │ │  public_access:  │ │  public_access:  │
│   true           │ │   false          │ │   false          │
│  node_pools:     │ │  node_pools:     │ │  node_pools:     │
│   basic only     │ │   all pools      │ │   all pools      │
└──────────────────┘ └──────────────────┘ └──────────────────┘
```

## Security Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Security Layers                             │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ Layer 1: Network Security                                 │ │
│  │  • VPC isolation                                          │ │
│  │  • Private subnets for nodes                              │ │
│  │  • Security groups (auto-managed)                         │ │
│  │  • Private cluster endpoint (optional)                    │ │
│  └───────────────────────────────────────────────────────────┘ │
│                             │                                   │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ Layer 2: Identity & Access Management                     │ │
│  │  • IAM roles with least privilege                         │ │
│  │  • EKS access entries                                     │ │
│  │  • No long-term credentials                               │ │
│  │  • OIDC provider for IRSA                                 │ │
│  └───────────────────────────────────────────────────────────┘ │
│                             │                                   │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ Layer 3: Data Encryption                                  │ │
│  │  • EBS volumes encrypted at rest                          │ │
│  │  • TLS for data in transit                                │ │
│  │  • Kubernetes secrets encrypted                           │ │
│  └───────────────────────────────────────────────────────────┘ │
│                             │                                   │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ Layer 4: Kubernetes RBAC                                  │ │
│  │  • Role-based access control                              │ │
│  │  • Service accounts                                       │ │
│  │  • Pod security standards                                 │ │
│  └───────────────────────────────────────────────────────────┘ │
│                             │                                   │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ Layer 5: Audit & Monitoring                               │ │
│  │  • CloudWatch logging                                     │ │
│  │  • Control plane logging                                  │ │
│  │  • VPC flow logs                                          │ │
│  │  • AWS CloudTrail                                         │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

These diagrams illustrate the complete architecture and workflows of the EKS Auto Mode blueprint!
