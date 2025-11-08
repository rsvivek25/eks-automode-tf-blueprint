# AWS EKS Auto Mode Terraform Blueprint - Documentation Index

Welcome to the comprehensive documentation for the AWS EKS Auto Mode Terraform Blueprint. This index will guide you to the right documentation based on your needs.

## 🚀 Quick Navigation

### Getting Started
- **New to this blueprint?** → Start with [BLUEPRINT_SUMMARY.md](BLUEPRINT_SUMMARY.md)
- **Ready to deploy?** → Follow [QUICKSTART.md](QUICKSTART.md)
- **Need comprehensive docs?** → Read [README.md](README.md)

### Planning & Design
- **Understanding the architecture** → See [ARCHITECTURE_DIAGRAMS.md](ARCHITECTURE_DIAGRAMS.md)
- **Project structure** → Review [STRUCTURE.md](STRUCTURE.md)
- **Client deployment planning** → Use [CLIENT_DEPLOYMENT_CHECKLIST.md](CLIENT_DEPLOYMENT_CHECKLIST.md)

### Migration
- **Migrating from existing EKS?** → Follow [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md)

### Customization
- **Adding node pools** → Check [examples/ADDITIONAL_NODEPOOLS.md](examples/ADDITIONAL_NODEPOOLS.md)
- **Modifying configuration** → See [terraform.tfvars.example](terraform.tfvars.example)

---

## 📚 Documentation Guide by Role

### For DevOps Engineers

**First Time Setup:**
1. [BLUEPRINT_SUMMARY.md](BLUEPRINT_SUMMARY.md) - Overview and features
2. [QUICKSTART.md](QUICKSTART.md) - Step-by-step deployment
3. [README.md](README.md) - Comprehensive reference

**Daily Operations:**
- [README.md - Usage Examples](README.md#usage-examples) - Deploy workloads
- [README.md - Troubleshooting](README.md#troubleshooting) - Fix common issues
- [examples/sample-app.yaml](examples/sample-app.yaml) - Reference deployment

**Customization:**
- [examples/ADDITIONAL_NODEPOOLS.md](examples/ADDITIONAL_NODEPOOLS.md) - Add custom pools
- [terraform.tfvars.example](terraform.tfvars.example) - Configuration options
- [STRUCTURE.md](STRUCTURE.md) - Understand file organization

### For Platform Architects

**Architecture & Design:**
1. [ARCHITECTURE_DIAGRAMS.md](ARCHITECTURE_DIAGRAMS.md) - Visual architecture
2. [README.md - Architecture](README.md#architecture) - Design principles
3. [STRUCTURE.md - Design Principles](STRUCTURE.md#design-principles) - Blueprint philosophy

**Planning:**
- [README.md - Prerequisites](README.md#prerequisites) - Requirements
- [README.md - Security Considerations](README.md#security-considerations) - Security design
- [CLIENT_DEPLOYMENT_CHECKLIST.md](CLIENT_DEPLOYMENT_CHECKLIST.md) - Deployment planning

**Migration:**
- [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md) - Migration strategies
- [MIGRATION_GUIDE.md - Timeline Estimation](MIGRATION_GUIDE.md#timeline-estimation) - Planning

### For Project Managers

**Overview:**
1. [BLUEPRINT_SUMMARY.md](BLUEPRINT_SUMMARY.md) - What's included
2. [README.md - Features](README.md#features) - Capabilities

**Planning:**
- [CLIENT_DEPLOYMENT_CHECKLIST.md](CLIENT_DEPLOYMENT_CHECKLIST.md) - Project checklist
- [MIGRATION_GUIDE.md - Timeline Estimation](MIGRATION_GUIDE.md#timeline-estimation) - Time estimates
- [MIGRATION_GUIDE.md - Cost Comparison](MIGRATION_GUIDE.md#cost-comparison) - Budget planning

### For Security Engineers

**Security Review:**
1. [README.md - Security Considerations](README.md#security-considerations) - Security features
2. [ARCHITECTURE_DIAGRAMS.md - Security Architecture](ARCHITECTURE_DIAGRAMS.md#security-architecture) - Security layers
3. [CLIENT_DEPLOYMENT_CHECKLIST.md - Security Hardening](CLIENT_DEPLOYMENT_CHECKLIST.md#security-hardening) - Hardening steps

**Configuration:**
- [terraform.tfvars.example](terraform.tfvars.example) - Security settings
- [README.md - Best Practices](README.md#security-considerations) - Security best practices

### For Developers

**Deploying Applications:**
1. [QUICKSTART.md - Deploy Sample Application](QUICKSTART.md#deploy-sample-application) - Quick start
2. [README.md - Usage Examples](README.md#usage-examples) - Deployment patterns
3. [examples/sample-app.yaml](examples/sample-app.yaml) - Reference application

**Node Pool Selection:**
- [README.md - Usage Examples](README.md#usage-examples) - How to select node pools
- [examples/ADDITIONAL_NODEPOOLS.md](examples/ADDITIONAL_NODEPOOLS.md) - Available options

---

## 📖 Documentation Files

### Core Documentation (Start Here)

#### [BLUEPRINT_SUMMARY.md](BLUEPRINT_SUMMARY.md)
**Executive summary of the blueprint**
- What's included
- Key features
- Quick start commands
- Cost considerations
- File inventory

**Best for:** First-time readers, executives, quick reference

---

#### [README.md](README.md)
**Comprehensive technical documentation**
- Complete feature list
- Architecture overview
- Prerequisites
- Configuration guide
- Usage examples
- Troubleshooting
- Security considerations
- Multi-environment setup

**Best for:** Technical teams, comprehensive reference, deep understanding

---

#### [QUICKSTART.md](QUICKSTART.md)
**Rapid deployment guide**
- Step-by-step instructions
- Prerequisites checklist
- Sample application deployment
- Common issues and solutions
- Clean-up instructions
- Production readiness checklist

**Best for:** Hands-on deployment, getting started quickly

---

### Architecture & Design

#### [ARCHITECTURE_DIAGRAMS.md](ARCHITECTURE_DIAGRAMS.md)
**Visual architecture documentation**
- High-level architecture
- Node pool architecture
- Workload deployment flow
- Storage provisioning flow
- Ingress/load balancer flow
- IAM role chain
- Multi-environment patterns
- Security architecture

**Best for:** Visual learners, architecture reviews, presentations

---

#### [STRUCTURE.md](STRUCTURE.md)
**Project organization and design**
- File structure explanation
- Design principles
- Usage workflow
- Customization guide
- Environment-specific deployments
- Maintenance procedures

**Best for:** Understanding code organization, contributing, customization

---

### Planning & Deployment

#### [CLIENT_DEPLOYMENT_CHECKLIST.md](CLIENT_DEPLOYMENT_CHECKLIST.md)
**Enterprise deployment checklist**
- Pre-deployment assessment
- Configuration preparation
- Deployment steps
- Post-deployment verification
- Documentation requirements
- Client handoff procedures
- Cost optimization
- Security hardening

**Best for:** Production deployments, client projects, quality assurance

---

#### [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md)
**Migration from existing EKS clusters**
- Migration strategies
- Pre-migration checklist
- Workload adaptation
- Data migration strategies
- Step-by-step examples
- Validation checklist
- Rollback plans
- Timeline estimation

**Best for:** Teams migrating from existing EKS clusters

---

### Configuration & Examples

#### [terraform.tfvars.example](terraform.tfvars.example)
**Configuration template**
- All configurable variables
- Example values
- Environment-specific settings
- Comments and explanations

**Best for:** Initial configuration, understanding options

---

#### [examples/sample-app.yaml](examples/sample-app.yaml)
**Reference application deployment**
- StatefulSet example
- PersistentVolumeClaim usage
- Service configuration
- Ingress with ALB
- Node pool selection

**Best for:** Learning deployment patterns, testing cluster

---

#### [examples/ADDITIONAL_NODEPOOLS.md](examples/ADDITIONAL_NODEPOOLS.md)
**Custom node pool examples**
- GPU node pools
- Spot instance pools
- Memory-optimized pools
- Configuration examples
- Best practices

**Best for:** Adding custom node pools, specialized workloads

---

## 🗂️ Terraform Files

### [main.tf](main.tf)
**Primary infrastructure configuration**
- Provider configurations
- VPC data sources
- EKS cluster module
- IAM roles and policies

---

### [variables.tf](variables.tf)
**Input variable definitions**
- General variables
- VPC variables
- Cluster configuration
- Auto Mode settings
- All configurable options

---

### [outputs.tf](outputs.tf)
**Output definitions**
- Cluster information
- IAM role details
- kubectl configuration
- VPC information

---

### [versions.tf](versions.tf)
**Version constraints**
- Terraform version requirements
- Provider versions
- Optional backend configuration

---

### [eks-automode-config.tf](eks-automode-config.tf)
**Auto Mode specific configuration**
- StorageClass deployment
- IngressClass deployment
- NodeClass deployment
- NodePool deployment

---

## 📁 Kubernetes Manifests (eks-automode-config/)

### Node Classes
- **[nodeclass-basic.yaml](eks-automode-config/nodeclass-basic.yaml)** - Basic EBS configuration
- **[nodeclass-ebs-optimized.yaml](eks-automode-config/nodeclass-ebs-optimized.yaml)** - Optimized EBS

### Node Pools
- **[nodepool-amd64.yaml](eks-automode-config/nodepool-amd64.yaml)** - x86_64 instances
- **[nodepool-graviton.yaml](eks-automode-config/nodepool-graviton.yaml)** - ARM64 instances

### Storage & Ingress
- **[ebs-storageclass.yaml](eks-automode-config/ebs-storageclass.yaml)** - EBS storage class
- **[alb-ingressclass.yaml](eks-automode-config/alb-ingressclass.yaml)** - ALB ingress class
- **[alb-ingressclassParams.yaml](eks-automode-config/alb-ingressclassParams.yaml)** - ALB parameters

---

## 🎯 Common Use Cases

### Use Case 1: First-Time Deployment
**Path:** 
1. [BLUEPRINT_SUMMARY.md](BLUEPRINT_SUMMARY.md)
2. [QUICKSTART.md](QUICKSTART.md)
3. [README.md](README.md) (reference as needed)

---

### Use Case 2: Client Deployment
**Path:**
1. [CLIENT_DEPLOYMENT_CHECKLIST.md](CLIENT_DEPLOYMENT_CHECKLIST.md)
2. [terraform.tfvars.example](terraform.tfvars.example)
3. [QUICKSTART.md](QUICKSTART.md)
4. [README.md - Troubleshooting](README.md#troubleshooting)

---

### Use Case 3: Migrating Existing Cluster
**Path:**
1. [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md)
2. [CLIENT_DEPLOYMENT_CHECKLIST.md](CLIENT_DEPLOYMENT_CHECKLIST.md)
3. [README.md](README.md)

---

### Use Case 4: Adding Custom Node Pools
**Path:**
1. [examples/ADDITIONAL_NODEPOOLS.md](examples/ADDITIONAL_NODEPOOLS.md)
2. [STRUCTURE.md - Adding Custom Configurations](STRUCTURE.md#adding-custom-configurations)
3. [terraform.tfvars.example](terraform.tfvars.example)

---

### Use Case 5: Troubleshooting Issues
**Path:**
1. [README.md - Troubleshooting](README.md#troubleshooting)
2. [QUICKSTART.md - Common Issues](QUICKSTART.md#common-issues--solutions)
3. GitHub Issues (if available)

---

### Use Case 6: Security Review
**Path:**
1. [README.md - Security Considerations](README.md#security-considerations)
2. [ARCHITECTURE_DIAGRAMS.md - Security Architecture](ARCHITECTURE_DIAGRAMS.md#security-architecture)
3. [CLIENT_DEPLOYMENT_CHECKLIST.md - Security Hardening](CLIENT_DEPLOYMENT_CHECKLIST.md#security-hardening)

---

## 🔍 Search Guide

### Looking for...

**Architecture diagrams?**
→ [ARCHITECTURE_DIAGRAMS.md](ARCHITECTURE_DIAGRAMS.md)

**Quick deployment steps?**
→ [QUICKSTART.md](QUICKSTART.md)

**Complete feature list?**
→ [BLUEPRINT_SUMMARY.md](BLUEPRINT_SUMMARY.md) or [README.md](README.md)

**Configuration options?**
→ [terraform.tfvars.example](terraform.tfvars.example) or [variables.tf](variables.tf)

**Example application?**
→ [examples/sample-app.yaml](examples/sample-app.yaml)

**Migration help?**
→ [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md)

**Security information?**
→ [README.md - Security](README.md#security-considerations)

**Cost information?**
→ [BLUEPRINT_SUMMARY.md - Cost](BLUEPRINT_SUMMARY.md#cost-considerations)

**Troubleshooting?**
→ [README.md - Troubleshooting](README.md#troubleshooting) or [QUICKSTART.md - Common Issues](QUICKSTART.md#common-issues--solutions)

**Production checklist?**
→ [CLIENT_DEPLOYMENT_CHECKLIST.md](CLIENT_DEPLOYMENT_CHECKLIST.md)

**Custom node pools?**
→ [examples/ADDITIONAL_NODEPOOLS.md](examples/ADDITIONAL_NODEPOOLS.md)

**File structure?**
→ [STRUCTURE.md](STRUCTURE.md)

---

## 📞 Getting Help

1. **Check documentation** - Use this index to find relevant docs
2. **Review examples** - See [examples/](examples/) directory
3. **Check troubleshooting** - [README.md](README.md) and [QUICKSTART.md](QUICKSTART.md)
4. **AWS documentation** - https://docs.aws.amazon.com/eks/
5. **Community support** - AWS forums, GitHub issues

---

## 🔄 Documentation Updates

This documentation is maintained alongside the blueprint code. Last updated: November 8, 2025

---

**Start your journey:** [BLUEPRINT_SUMMARY.md](BLUEPRINT_SUMMARY.md) → [QUICKSTART.md](QUICKSTART.md) → Deploy! 🚀
