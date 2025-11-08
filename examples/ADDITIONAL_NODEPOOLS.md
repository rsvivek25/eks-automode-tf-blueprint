# Additional NodePool and NodeClass Examples

This directory contains example configurations for extending the blueprint with additional node pools.

## GPU Node Pool Example

### 1. Create NodeClass for GPU instances

**File**: `eks-automode-config/nodeclass-gpu.yaml`

```yaml
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
    WorkloadType: "gpu"
```

### 2. Create NodePool for GPU instances

**File**: `eks-automode-config/nodepool-gpu.yaml`

```yaml
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
        - key: "kubernetes.io/arch"
          operator: In
          values: ["amd64"]
        - key: "node.kubernetes.io/instance-type"
          operator: In
          values:
            - "p3.2xlarge"
            - "p3.8xlarge"
            - "p3.16xlarge"
            - "g4dn.xlarge"
            - "g4dn.2xlarge"
            - "g4dn.4xlarge"
            - "g4dn.8xlarge"
        - key: "eks.amazonaws.com/instance-hypervisor"
          operator: In
          values: ["nitro"]
      nodeClassRef:
        name: gpu
        group: eks.amazonaws.com
        kind: NodeClass
  limits:
    cpu: 500
    memory: 2000Gi
```

### 3. Update terraform.tfvars

```hcl
custom_nodeclass_yamls = [
  "nodeclass-basic.yaml",
  "nodeclass-ebs-optimized.yaml",
  "nodeclass-gpu.yaml"
]

custom_nodepool_yamls = [
  "nodepool-amd64.yaml",
  "nodepool-graviton.yaml",
  "nodepool-gpu.yaml"
]
```

### 4. Deploy GPU Workload

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: gpu-pod
spec:
  nodeSelector:
    NodeGroupType: GPU
  tolerations:
    - key: nvidia.com/gpu
      effect: NoSchedule
  containers:
    - name: cuda-container
      image: nvidia/cuda:11.0-base
      resources:
        limits:
          nvidia.com/gpu: 1
```

## Spot Instance Node Pool Example

### NodePool for Spot Instances

**File**: `eks-automode-config/nodepool-spot.yaml`

```yaml
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: spot
spec:
  template:
    metadata:
      labels:
        type: karpenter
        provisioner: spot
        NodeGroupType: Spot
    spec:
      taints:
        - key: spot
          effect: NoSchedule
      requirements:
        - key: "karpenter.sh/capacity-type"
          operator: In
          values: ["spot"]
        - key: "kubernetes.io/arch"
          operator: In
          values: ["amd64"]
        - key: "eks.amazonaws.com/instance-category"
          operator: In
          values: ["c", "m", "r"]
        - key: "eks.amazonaws.com/instance-cpu"
          operator: In
          values: ["4", "8", "16"]
      nodeClassRef:
        name: basic
        group: eks.amazonaws.com
        kind: NodeClass
  limits:
    cpu: 500
  disruption:
    consolidationPolicy: WhenUnderutilized
    expireAfter: 720h
```

## Memory-Optimized Node Pool Example

### NodePool for Memory-Intensive Workloads

**File**: `eks-automode-config/nodepool-memory-optimized.yaml`

```yaml
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: memory-optimized
spec:
  template:
    metadata:
      labels:
        type: karpenter
        provisioner: memory-optimized
        NodeGroupType: MemoryOptimized
    spec:
      taints:
        - key: memory-optimized
          effect: NoSchedule
      requirements:
        - key: "karpenter.sh/capacity-type"
          operator: In
          values: ["on-demand"]
        - key: "kubernetes.io/arch"
          operator: In
          values: ["amd64"]
        - key: "eks.amazonaws.com/instance-category"
          operator: In
          values: ["r", "x"]  # R and X instance families
        - key: "eks.amazonaws.com/instance-cpu"
          operator: In
          values: ["8", "16", "32", "64"]
        - key: "eks.amazonaws.com/instance-hypervisor"
          operator: In
          values: ["nitro"]
        - key: "eks.amazonaws.com/instance-generation"
          operator: Gt
          values: ["5"]
      nodeClassRef:
        name: ebs-optimized
        group: eks.amazonaws.com
        kind: NodeClass
  limits:
    cpu: 500
    memory: 4000Gi
```

## Deployment Instructions

1. Copy the desired YAML files to `eks-automode-config/`
2. Update `terraform.tfvars` to include the new files
3. Run `terraform apply`
4. Deploy workloads with appropriate node selectors and tolerations

## Node Selector Examples

### For GPU Workloads
```yaml
nodeSelector:
  NodeGroupType: GPU
tolerations:
  - key: nvidia.com/gpu
    effect: NoSchedule
```

### For Spot Instances
```yaml
nodeSelector:
  NodeGroupType: Spot
tolerations:
  - key: spot
    effect: NoSchedule
```

### For Memory-Optimized
```yaml
nodeSelector:
  NodeGroupType: MemoryOptimized
tolerations:
  - key: memory-optimized
    effect: NoSchedule
```

## Best Practices

1. **Use Taints and Tolerations**: Prevent pods from accidentally scheduling on expensive instance types
2. **Set Resource Limits**: Define CPU and memory limits on NodePools to control costs
3. **Use Appropriate Instance Families**: Match instance types to workload requirements
4. **Monitor Costs**: Use AWS Cost Explorer to track spending by node pool
5. **Test Thoroughly**: Validate new node pools in dev/staging before production
