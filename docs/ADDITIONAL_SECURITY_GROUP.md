# Additional Security Group Configuration

## Overview

This blueprint supports creating an **additional security group** that gets attached to your EKS cluster. This is useful when you need to allow specific inbound traffic to the cluster control plane from sources like:

- On-premises networks
- Corporate VPN networks
- Bastion hosts or jump servers
- Management tools and monitoring systems

The additional security group is created and managed by Terraform with:
- ✅ **All outbound traffic allowed** (default egress rule: 0.0.0.0/0)
- ✅ **Configurable inbound rules** with customizable CIDR blocks
- ✅ **Multiple ingress rules** support (HTTPS, SSH, custom ports)

## Why Use an Additional Security Group?

When creating an EKS cluster through the AWS Console, you can attach additional security groups. This is commonly used to:

1. **Allow traffic from on-premises networks** - Enable hybrid cloud connectivity
2. **Restrict access to specific networks** - Implement least-privilege access
3. **Separate concerns** - Keep cluster-managed security groups separate from custom rules
4. **Support legacy systems** - Allow access from specific IP ranges or networks

## Configuration

### Basic Configuration

Enable the additional security group in your `terraform.tfvars`:

```hcl
# Enable additional security group
create_additional_security_group = true

# Specify CIDR blocks that can access the cluster
additional_security_group_ingress_cidr_blocks = [
  "10.0.0.0/8",      # Corporate network
  "172.16.0.0/12"    # VPN network
]
```

This creates a security group with:
- Default name: `<cluster_name>-additional-sg`
- Default ingress rule: HTTPS (443) from specified CIDR blocks
- Default egress rule: All traffic allowed (0.0.0.0/0)

### Custom Security Group Name

Override the default security group name:

```hcl
create_additional_security_group = true
additional_security_group_name   = "my-custom-eks-sg"
```

### Custom Ingress Rules

Define custom ingress rules for different ports and protocols:

```hcl
create_additional_security_group = true

additional_security_group_ingress_cidr_blocks = [
  "10.0.0.0/8",
  "172.16.0.0/12"
]

additional_security_group_ingress_rules = [
  {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    description = "HTTPS access from corporate network"
  },
  {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    description = "SSH access from bastion hosts"
  },
  {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    description = "Custom application port"
  }
]
```

### Multiple CIDR Blocks

Allow access from multiple networks:

```hcl
additional_security_group_ingress_cidr_blocks = [
  "10.0.0.0/8",           # Corporate network (RFC 1918)
  "172.16.0.0/12",        # VPN network (RFC 1918)
  "192.168.1.0/24",       # Specific subnet
  "203.0.113.10/32"       # Specific IP address
]
```

## Variables Reference

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `create_additional_security_group` | bool | `false` | Enable/disable additional security group creation |
| `additional_security_group_name` | string | `""` | Custom name (defaults to `<cluster_name>-additional-sg`) |
| `additional_security_group_description` | string | `"Additional security group for EKS cluster"` | Security group description |
| `additional_security_group_ingress_cidr_blocks` | list(string) | `[]` | CIDR blocks for ingress rules |
| `additional_security_group_ingress_rules` | list(object) | See below | List of ingress rules |

### Default Ingress Rule

```hcl
[
  {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    description = "HTTPS access"
  }
]
```

## Outputs

The blueprint provides outputs for the additional security group:

```hcl
output "additional_security_group_id" {
  value = var.create_additional_security_group ? aws_security_group.additional[0].id : null
}

output "additional_security_group_arn" {
  value = var.create_additional_security_group ? aws_security_group.additional[0].arn : null
}
```

Use these outputs in other modules or for reference:

```bash
terraform output additional_security_group_id
# Output: sg-0abc123def456789a
```

## Use Cases

### 1. Allow Access from On-Premises Network

```hcl
create_additional_security_group = true

additional_security_group_ingress_cidr_blocks = [
  "10.0.0.0/8"  # On-premises network
]

additional_security_group_ingress_rules = [
  {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    description = "HTTPS access from on-premises"
  }
]
```

### 2. Bastion Host Access

```hcl
create_additional_security_group = true

additional_security_group_ingress_cidr_blocks = [
  "10.0.1.0/24"  # Bastion host subnet
]

additional_security_group_ingress_rules = [
  {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    description = "SSH from bastion hosts"
  },
  {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    description = "HTTPS from bastion hosts"
  }
]
```

### 3. Multi-Network Access

```hcl
create_additional_security_group = true

additional_security_group_ingress_cidr_blocks = [
  "10.0.0.0/8",      # Corporate HQ
  "172.16.0.0/12",   # Branch offices
  "192.168.1.0/24"   # Remote office
]

additional_security_group_ingress_rules = [
  {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    description = "HTTPS access from all corporate networks"
  }
]
```

## Security Best Practices

### ✅ DO

- **Use specific CIDR blocks** - Avoid using `0.0.0.0/0` for production clusters
- **Document each CIDR block** - Add comments explaining what each network is
- **Use the principle of least privilege** - Only open required ports
- **Combine with private endpoint access** - Set `cluster_endpoint_public_access = false`
- **Enable VPC flow logs** - Monitor traffic to the security group
- **Regular audits** - Review security group rules periodically

### ❌ DON'T

- **Avoid 0.0.0.0/0** - Don't allow unrestricted access in production
- **Don't duplicate rules** - Each rule should serve a specific purpose
- **Don't allow unnecessary ports** - Stick to required protocols only
- **Don't forget documentation** - Always add meaningful descriptions

## Integration with EKS Cluster

The additional security group is automatically attached to the EKS cluster:

```hcl
# In main.tf
module "eks" {
  # ... other configuration ...

  cluster_additional_security_group_ids = var.create_additional_security_group ? [aws_security_group.additional[0].id] : []
}
```

## Verification

After creating the cluster, verify the security group attachment:

```bash
# Get cluster security groups
aws eks describe-cluster \
  --name my-eks-automode-cluster \
  --query 'cluster.resourcesVpcConfig.securityGroupIds' \
  --output table

# Describe the additional security group
aws ec2 describe-security-groups \
  --group-ids $(terraform output -raw additional_security_group_id) \
  --output table
```

## Troubleshooting

### Security Group Not Attached

**Problem**: The additional security group is created but not attached to the cluster.

**Solution**: 
1. Check that `create_additional_security_group = true`
2. Verify the output: `terraform output additional_security_group_id`
3. Re-run `terraform apply`

### Cannot Access Cluster

**Problem**: Cannot access the cluster even with the security group configured.

**Solution**:
1. **Verify CIDR blocks**: Ensure your source IP is in `additional_security_group_ingress_cidr_blocks`
2. **Check cluster endpoint access**: Verify `cluster_endpoint_public_access` setting
3. **Test connectivity**:
   ```bash
   # Test HTTPS connectivity
   telnet <cluster-endpoint> 443
   
   # Check kubectl access
   kubectl cluster-info
   ```
4. **Review all security groups**: The cluster may have multiple security groups - check all of them

### Terraform Errors

**Problem**: Error creating security group rules.

**Solution**:
1. **Validate CIDR blocks**: Ensure they are valid CIDR notation
   ```bash
   # Valid: 10.0.0.0/8, 172.16.0.0/12, 192.168.1.0/24
   # Invalid: 10.0.0.0, 10.0.0.0/33
   ```
2. **Check port ranges**: Ensure from_port ≤ to_port
3. **Verify protocol**: Use "tcp", "udp", "icmp", or "-1" (all)

## Example: Complete Configuration

```hcl
# terraform.tfvars

# Enable additional security group
create_additional_security_group = true
additional_security_group_name   = "prod-eks-additional-sg"

# Allow access from multiple networks
additional_security_group_ingress_cidr_blocks = [
  "10.0.0.0/8",       # Corporate network
  "172.16.50.0/24",   # Bastion subnet
  "203.0.113.100/32"  # Admin workstation
]

# Define ingress rules
additional_security_group_ingress_rules = [
  {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    description = "HTTPS access for kubectl and API calls"
  },
  {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    description = "SSH access for node troubleshooting (bastion only)"
  }
]

# Cluster endpoint configuration
cluster_endpoint_public_access  = false  # Private cluster
cluster_endpoint_private_access = true

# Tags
tags = {
  Environment = "production"
  Team        = "platform"
  Purpose     = "eks-access-control"
}
```

## Related Documentation

- [VPC Endpoint Requirements](VPC_ENDPOINT_REQUIREMENTS.md) - For fully private clusters
- [IAM Permissions](IAM_PERMISSIONS.md) - Required IAM policies
- [Security Best Practices](../README.md#security-features) - Overall security configuration

## References

- [AWS EKS Security Groups](https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html)
- [AWS VPC Security Groups](https://docs.aws.amazon.com/vpc/latest/userguide/security-groups.html)
- [Terraform AWS Security Group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group)
