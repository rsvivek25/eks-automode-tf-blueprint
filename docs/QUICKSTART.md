# Quick Start Guide - EKS Auto Mode Blueprint

This guide will help you deploy your first EKS Auto Mode cluster in under 15 minutes.

## Prerequisites Checklist

- [ ] Terraform >= 1.3 installed
- [ ] AWS CLI configured with valid credentials
- [ ] kubectl installed
- [ ] Existing VPC with private subnets
- [ ] VPC has NAT Gateway configured
- [ ] Subnets are properly tagged

## Step-by-Step Deployment

### Step 1: Prepare Configuration

```bash
# Navigate to the blueprint directory
cd terraform-eks

# Copy the example configuration
cp terraform.tfvars.example terraform.tfvars
```

### Step 2: Edit Configuration

Open `terraform.tfvars` and set these **required** values:

```hcl
# REQUIRED: Set your cluster name
cluster_name = "my-eks-cluster"

# REQUIRED: Set your existing VPC ID
vpc_id = "vpc-0123456789abcdef0"

# REQUIRED: Set your AWS region
aws_region = "us-east-1"

# REQUIRED: Update subnet tags to match your VPC
private_subnet_tags = {
  "kubernetes.io/role/internal-elb" = "1"
  # Or use your custom tags
}

# RECOMMENDED: Add resource tags
tags = {
  Environment = "dev"
  Owner       = "your-team"
}
```

### Step 3: Initialize Terraform

```bash
terraform init
```

Expected output:
```
Terraform has been successfully initialized!
```

### Step 4: Validate Configuration

```bash
terraform validate
```

### Step 5: Review Planned Changes

```bash
terraform plan
```

Review the output to ensure:
- Cluster will be created in the correct VPC
- Subnets are correctly identified
- IAM roles will be created
- Custom NodePools and NodeClasses will be applied

### Step 6: Deploy the Cluster

```bash
terraform apply
```

When prompted, type `yes` to confirm.

**⏱️ Deployment time**: Approximately 10-15 minutes

### Step 7: Configure kubectl

After successful deployment, configure kubectl:

```bash
# Option 1: Use the Terraform output
terraform output -raw configure_kubectl | sh

# Option 2: Manually configure
aws eks update-kubeconfig --region <your-region> --name <cluster-name>
```

### Step 8: Verify the Cluster

```bash
# Check cluster connection
kubectl cluster-info

# List nodes (may be empty initially)
kubectl get nodes

# Check NodePools
kubectl get nodepools

# Check NodeClasses
kubectl get nodeclasses -A

# Check StorageClasses
kubectl get storageclass

# Check IngressClasses
kubectl get ingressclass
```

## Deploy Sample Application

Test your cluster with the included sample application:

```bash
# Deploy the sample app
kubectl apply -f examples/sample-app.yaml

# Watch nodes being provisioned
kubectl get nodes -w

# Check pods
kubectl get pods -n sample-app

# Check persistent volumes
kubectl get pvc -n sample-app

# Get the ALB URL
kubectl get ingress -n sample-app
```

Wait a few minutes for the ALB to be provisioned, then access your application:

```bash
# Get the ALB DNS name
ALB_URL=$(kubectl get ingress httpd-ingress -n sample-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Application URL: http://$ALB_URL"

# Test the application
curl http://$ALB_URL
```

## Common Issues & Solutions

### Issue: Subnets not found

**Solution**: Verify your `private_subnet_tags` match your actual subnet tags:

```bash
# List your VPC subnets
aws ec2 describe-subnets --filters "Name=vpc-id,Values=<your-vpc-id>" --query 'Subnets[*].[SubnetId,Tags]'
```

Update `private_subnet_tags` in `terraform.tfvars` to match.

### Issue: kubectl connection timeout

**Solution**: 
1. Check if cluster endpoint is accessible:
   ```bash
   terraform output cluster_endpoint
   ```

2. Update kubeconfig:
   ```bash
   aws eks update-kubeconfig --region <region> --name <cluster-name>
   ```

3. Verify AWS credentials:
   ```bash
   aws sts get-caller-identity
   ```

### Issue: Nodes not provisioning

**Solution**: Check NodePool status:

```bash
kubectl describe nodepool amd64
kubectl describe nodepool graviton
```

Common causes:
- Incorrect subnet tags in NodeClass
- Security group configuration
- IAM role issues

## Clean Up

When you're done testing, clean up resources to avoid charges:

```bash
# Delete sample application
kubectl delete -f examples/sample-app.yaml

# Wait for resources to be deleted (especially LoadBalancers)
sleep 60

# Destroy the cluster
terraform destroy
```

Type `yes` when prompted.

## Next Steps

Now that your cluster is running:

1. **Deploy Your Applications**: Use the sample app as a template
2. **Configure Monitoring**: Set up CloudWatch Container Insights
3. **Set Up CI/CD**: Integrate with your deployment pipeline
4. **Implement Security**: Enable audit logging, configure network policies
5. **Optimize Costs**: Review node pool configurations and limits

## Production Readiness Checklist

Before deploying to production:

- [ ] Set `cluster_endpoint_public_access = false`
- [ ] Configure VPN or bastion host for cluster access
- [ ] Enable audit logging
- [ ] Set up backup and disaster recovery
- [ ] Configure monitoring and alerting
- [ ] Implement network policies
- [ ] Set up Terraform remote state backend
- [ ] Document runbooks and procedures
- [ ] Configure auto-scaling limits
- [ ] Review and adjust IAM policies

## Get Help

- Review the full [README.md](README.md) for detailed documentation
- Check [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- Review [Terraform AWS EKS Module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/)

---

**Estimated Cost**: Running this cluster will incur AWS charges. Review the [AWS Pricing Calculator](https://calculator.aws/) for estimates.
