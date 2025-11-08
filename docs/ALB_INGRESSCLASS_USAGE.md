# ALB IngressClass Usage Guide

## Overview

Your blueprint now includes **two ALB IngressClass configurations**:

1. **`alb`** - Internet-facing (public) load balancers
2. **`alb-internal`** - Internal (private VPC-only) load balancers

---

## Files Included

### Public ALB (Internet-Facing)
- `alb-ingressclass.yaml` - IngressClass definition
- `alb-ingressclassParams.yaml` - Configuration with `scheme: internet-facing`

### Internal ALB (VPC-Only)
- `alb-ingressclass-internal.yaml` - IngressClass definition
- `alb-ingressclassParams-internal.yaml` - Configuration with `scheme: internal`

---

## Usage Examples

### Public ALB (Internet-Facing)

Use for applications that need to be accessible from the internet:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: public-web-app
  annotations:
    kubernetes.io/ingress.class: alb
spec:
  rules:
    - host: www.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: web-app
                port:
                  number: 80
```

**Result:**
- Creates ALB in public subnets
- Accessible from the internet
- ALB DNS: `public-web-app-xxx.us-east-1.elb.amazonaws.com` (public IP)

---

### Internal ALB (Private VPC-Only)

Use for internal applications, admin panels, or microservices:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: internal-admin
  annotations:
    kubernetes.io/ingress.class: alb-internal  # ← Note: alb-internal
spec:
  rules:
    - host: admin.internal.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: admin-panel
                port:
                  number: 80
```

**Result:**
- Creates ALB in private subnets
- Accessible only within VPC (or via VPN/Direct Connect)
- ALB DNS: `internal-admin-xxx.us-east-1.elb.amazonaws.com` (private IP)

---

## Default IngressClass

Currently, **`alb` (public)** is set as the default IngressClass.

### If Ingress doesn't specify a class:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app
  # No kubernetes.io/ingress.class annotation
spec:
  rules:
    - http:
        paths:
          - path: /
            backend:
              service:
                name: my-app
                port:
                  number: 80
```

**Result:** Uses `alb` (public/internet-facing) by default.

---

## Changing the Default

### To make internal ALB the default (recommended for private clusters):

Edit `eks-automode-config/alb-ingressclass-internal.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: alb-internal
  annotations:
    ingressclass.kubernetes.io/is-default-class: "true"  # ← Add this
spec:
  controller: eks.amazonaws.com/alb
  parameters:
    apiGroup: eks.amazonaws.com
    kind: IngressClassParams
    name: alb-internal
```

And remove the default annotation from `alb-ingressclass.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: alb
  # annotations:
  #   ingressclass.kubernetes.io/is-default-class: "true"  # ← Remove or comment
spec:
  controller: eks.amazonaws.com/alb
  parameters:
    apiGroup: eks.amazonaws.com
    kind: IngressClassParams
    name: alb
```

---

## Subnet Requirements

### For Public ALB (Internet-Facing)

Your **public subnets** must have this tag:
```
kubernetes.io/role/elb = 1
```

### For Internal ALB (VPC-Only)

Your **private subnets** must have this tag:
```
kubernetes.io/role/internal-elb = 1
```

**Note:** The blueprint expects this tag via the `private_subnet_tags` variable in `terraform.tfvars`:

```hcl
private_subnet_tags = {
  "kubernetes.io/role/internal-elb" = "1"
}
```

---

## Verification

### Check available IngressClasses:

```bash
kubectl get ingressclass

NAME           CONTROLLER              PARAMETERS        AGE
alb            eks.amazonaws.com/alb   alb              1d
alb-internal   eks.amazonaws.com/alb   alb-internal     1d
```

### Check IngressClassParams:

```bash
kubectl get ingressclassparams

NAME           AGE
alb            1d
alb-internal   1d
```

### View details:

```bash
kubectl describe ingressclassparams alb
# Should show: scheme: internet-facing

kubectl describe ingressclassparams alb-internal
# Should show: scheme: internal
```

### Verify ALB scheme after creating Ingress:

```bash
# Get the Ingress
kubectl get ingress my-app

# Get ALB details from AWS
ALB_DNS=$(kubectl get ingress my-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
aws elbv2 describe-load-balancers --query "LoadBalancers[?DNSName=='$ALB_DNS'].{Scheme:Scheme,Subnets:AvailabilityZones[*].SubnetId}" --output table
```

---

## Best Practices

### 1. Be Explicit

Always specify the IngressClass annotation:

```yaml
# ✅ Good
metadata:
  annotations:
    kubernetes.io/ingress.class: alb-internal

# ⚠️ Risky - relies on default
metadata:
  # No annotation
```

### 2. Use Internal by Default (Security)

For production clusters, consider making `alb-internal` the default and explicitly opt-in to public ALBs.

### 3. Security Groups

Internal ALBs can use more restrictive security groups:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: internal-app
  annotations:
    kubernetes.io/ingress.class: alb-internal
    alb.ingress.kubernetes.io/security-groups: sg-0123456789abcdef0  # Custom SG
spec:
  # ...
```

### 4. Test Both Configurations

```bash
# Deploy test apps with both IngressClasses
kubectl apply -f test-public-ingress.yaml
kubectl apply -f test-internal-ingress.yaml

# Verify public is accessible from internet
curl http://<public-alb-dns>

# Verify internal is NOT accessible from internet (should timeout)
curl http://<internal-alb-dns>  # Should fail

# Verify internal IS accessible from within VPC
# SSH/SSM into a node or pod:
kubectl exec -it test-pod -- curl http://<internal-alb-dns>  # Should succeed
```

---

## Comparison Table

| Aspect | `alb` (Public) | `alb-internal` (Private) |
|--------|----------------|--------------------------|
| **Scheme** | internet-facing | internal |
| **Subnet Type** | Public | Private |
| **Internet Access** | ✅ Yes | ❌ No |
| **VPC Access** | ✅ Yes | ✅ Yes |
| **VPN Access** | ✅ Yes | ✅ Yes |
| **Use Cases** | Public websites, APIs | Admin panels, internal services |
| **Security** | ⚠️ Exposed | ✅ Protected |
| **Default** | ✅ Yes | ❌ No (can be changed) |

---

## Troubleshooting

### ALB not created

```bash
# Check Ingress status
kubectl describe ingress my-app

# Common issues:
# 1. Missing subnet tags (kubernetes.io/role/elb or kubernetes.io/role/internal-elb)
# 2. Incorrect IngressClass name
# 3. AWS Load Balancer Controller not running
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```

### Wrong ALB scheme created

```bash
# Verify IngressClass annotation
kubectl get ingress my-app -o yaml | grep -A 2 annotations

# Should see:
#   kubernetes.io/ingress.class: alb-internal
# Or:
#   kubernetes.io/ingress.class: alb
```

### Internal ALB accessible from internet

This shouldn't happen if configured correctly. Verify:

```bash
# Check ALB scheme
aws elbv2 describe-load-balancers --query "LoadBalancers[?DNSName=='<alb-dns>'].Scheme"
# Should return: "internal"

# Check subnets
aws elbv2 describe-load-balancers --query "LoadBalancers[?DNSName=='<alb-dns>'].AvailabilityZones[*].SubnetId"
# Should return only private subnet IDs
```

---

## Summary

You now have **both public and internal ALB options**:

- ✅ `alb` - For public-facing applications
- ✅ `alb-internal` - For VPC-only applications
- ✅ Easy to switch between them using annotations
- ✅ Can use both simultaneously in the same cluster

Choose the appropriate IngressClass based on your security requirements! 🎯
