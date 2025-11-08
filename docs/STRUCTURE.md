# EKS Auto Mode Terraform Blueprint - Project Structure

```
terraform-eks/
│
├── main.tf                          # Main EKS cluster configuration
├── variables.tf                     # Input variable definitions
├── outputs.tf                       # Output value definitions
├── versions.tf                      # Terraform and provider version constraints
├── eks-automode-config.tf          # Auto Mode specific configurations
│
├── terraform.tfvars.example        # Example configuration file
├── .gitignore                      # Git ignore rules
│
├── README.md                        # Comprehensive documentation
├── QUICKSTART.md                    # Quick start guide
│
├── eks-automode-config/            # Kubernetes manifests for Auto Mode
│   ├── nodeclass-basic.yaml        # Basic NodeClass configuration
│   ├── nodeclass-ebs-optimized.yaml # EBS-optimized NodeClass
│   ├── nodepool-amd64.yaml         # AMD64/x86_64 NodePool
│   ├── nodepool-graviton.yaml      # ARM64/Graviton NodePool
│   ├── ebs-storageclass.yaml       # EBS StorageClass configuration
│   ├── alb-ingressclass.yaml       # ALB IngressClass configuration
│   └── alb-ingressclassParams.yaml # ALB IngressClass parameters
│
└── examples/                        # Example deployments and configurations
    ├── sample-app.yaml              # Sample application deployment
    └── ADDITIONAL_NODEPOOLS.md     # Examples for additional node pools

```

## File Descriptions

### Core Terraform Files

#### `main.tf`
- Provider configurations (AWS, Helm, kubectl)
- Data sources for VPC and subnet discovery
- EKS cluster module configuration
- IAM role creation for custom node classes
- IAM policy attachments

#### `variables.tf`
- All configurable parameters
- Organized into sections:
  - General variables (region, cluster name)
  - VPC variables (existing VPC configuration)
  - EKS cluster configuration
  - IAM configuration
  - Auto Mode configuration
- Includes descriptions and default values

#### `outputs.tf`
- Cluster information (ID, ARN, endpoint)
- IAM role details
- kubectl configuration commands
- Auto Mode status
- VPC and subnet information

#### `versions.tf`
- Terraform version constraints
- Provider version specifications
- Optional backend configuration (commented)

#### `eks-automode-config.tf`
- kubectl_manifest resources for:
  - Storage classes
  - Ingress classes
  - Custom NodeClasses
  - Custom NodePools
- Dependency management between resources

### Configuration Files

#### `terraform.tfvars.example`
- Example configuration for different environments
- Comments explaining each setting
- Security best practices
- Client-specific customization guide

#### `.gitignore`
- Excludes sensitive files (*.tfvars, *.tfstate)
- Ignores Terraform working directories
- Excludes IDE and system files

### Kubernetes Manifests

#### NodeClass Configurations

**`nodeclass-basic.yaml`**
- Basic EBS configuration
- Standard IOPS and throughput
- Suitable for general workloads

**`nodeclass-ebs-optimized.yaml`**
- Optimized EBS performance
- Higher IOPS and throughput
- For I/O intensive workloads

#### NodePool Configurations

**`nodepool-amd64.yaml`**
- x86_64 architecture instances
- C, M, R instance families
- On-demand capacity

**`nodepool-graviton.yaml`**
- ARM64/Graviton instances
- Cost-optimized for compatible workloads
- Better price-performance ratio

#### Storage and Ingress

**`ebs-storageclass.yaml`**
- Default storage class for EBS
- GP3 volumes with encryption
- WaitForFirstConsumer binding mode

**`alb-ingressclass.yaml`**
- Application Load Balancer integration
- Default ingress class
- Internet-facing scheme

**`alb-ingressclassParams.yaml`**
- ALB-specific parameters
- Scheme configuration

### Documentation

#### `README.md`
- Comprehensive blueprint documentation
- Architecture overview
- Prerequisites and setup instructions
- Configuration guide
- Usage examples
- Troubleshooting guide
- Security considerations

#### `QUICKSTART.md`
- Step-by-step deployment guide
- Configuration checklist
- Sample application deployment
- Common issues and solutions
- Clean-up instructions

### Examples

#### `examples/sample-app.yaml`
- StatefulSet deployment
- PersistentVolumeClaim usage
- Service configuration
- Ingress with ALB
- Demonstrates NodePool selection

#### `examples/ADDITIONAL_NODEPOOLS.md`
- GPU node pool example
- Spot instance configuration
- Memory-optimized instances
- Custom node pool patterns
- Best practices

## Usage Workflow

1. **Initial Setup**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your configuration
   ```

2. **Deployment**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

3. **Post-Deployment**
   ```bash
   # Configure kubectl
   aws eks update-kubeconfig --region <region> --name <cluster>
   
   # Deploy sample app
   kubectl apply -f examples/sample-app.yaml
   ```

4. **Customization**
   - Add custom NodeClasses to `eks-automode-config/`
   - Add custom NodePools to `eks-automode-config/`
   - Update `terraform.tfvars` to include new files
   - Apply changes with `terraform apply`

## Design Principles

### 1. **Reusability**
   - Parameterized through variables
   - Works with any existing VPC
   - Easy to customize for different clients

### 2. **Security**
   - Private cluster endpoint by default
   - Encrypted EBS volumes
   - IAM best practices
   - No hardcoded credentials

### 3. **Flexibility**
   - Enable/disable features through variables
   - Custom node pools and classes
   - Environment-specific configurations

### 4. **Production-Ready**
   - Comprehensive documentation
   - Error handling
   - Validation and testing examples
   - Clean-up procedures

### 5. **Best Practices**
   - Follows AWS EKS best practices
   - Uses official Terraform modules
   - Implements security hardening
   - Includes monitoring and observability hooks

## Adding Custom Configurations

### Adding a New NodeClass

1. Create YAML file in `eks-automode-config/`:
   ```yaml
   # nodeclass-custom.yaml
   apiVersion: eks.amazonaws.com/v1
   kind: NodeClass
   metadata:
     name: custom
   spec:
     role: "${node_iam_role_name}"
     # ... configuration
   ```

2. Update `terraform.tfvars`:
   ```hcl
   custom_nodeclass_yamls = [
     "nodeclass-basic.yaml",
     "nodeclass-ebs-optimized.yaml",
     "nodeclass-custom.yaml"
   ]
   ```

### Adding a New NodePool

1. Create YAML file in `eks-automode-config/`:
   ```yaml
   # nodepool-custom.yaml
   apiVersion: karpenter.sh/v1
   kind: NodePool
   metadata:
     name: custom
   # ... configuration
   ```

2. Update `terraform.tfvars`:
   ```hcl
   custom_nodepool_yamls = [
     "nodepool-amd64.yaml",
     "nodepool-graviton.yaml",
     "nodepool-custom.yaml"
   ]
   ```

## Environment-Specific Deployments

### Development
- Use `terraform.tfvars.dev`
- Enable public endpoint for easier access
- Smaller instance types

### Staging
- Use `terraform.tfvars.staging`
- Mirror production configuration
- Enable additional logging

### Production
- Use `terraform.tfvars.prod`
- Private endpoints only
- High availability configuration
- Enhanced monitoring

Deploy with:
```bash
terraform apply -var-file=terraform.tfvars.prod
```

## Maintenance

### Updates
1. Review new Kubernetes versions
2. Update `cluster_version` variable
3. Test in dev/staging
4. Update documentation

### Backups
1. Use Terraform remote state
2. Version control all configurations
3. Document infrastructure changes

### Monitoring
1. Enable CloudWatch Container Insights
2. Set up alerting
3. Monitor costs and usage
