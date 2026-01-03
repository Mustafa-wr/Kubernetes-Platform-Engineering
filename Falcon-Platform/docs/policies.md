# Policy Enforcement

## Overview

Kyverno enforces security and operational policies at admission time. Non-compliant workloads are rejected before deployment.

## Installation

Kyverno is deployed via ArgoCD:

```yaml
# gitops/apps/kyverno.yaml
source:
  repoURL: https://kyverno.github.io/kyverno/
  chart: kyverno
  targetRevision: 3.0.1
```

## Active Policies

### disallow-root-user

Blocks containers running as root.

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: disallow-root-user
spec:
  validationFailureAction: Enforce
  rules:
    - name: check-run-as-non-root
      match:
        any:
        - resources:
            kinds:
            - Pod
      validate:
        message: "Running as root is forbidden. Set securityContext.runAsNonRoot to true."
        pattern:
          spec:
            securityContext:
              runAsNonRoot: true
```

**Compliant Pod:**
```yaml
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
```

### disallow-latest-tag

Prevents use of mutable `:latest` image tags.

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: disallow-latest-tag
spec:
  validationFailureAction: Enforce
  rules:
    - name: validate-image-tag
      match:
        any:
        - resources:
            kinds:
            - Pod
      validate:
        message: "Using 'latest' tag is forbidden. Please specify a version."
        pattern:
          spec:
            containers:
            - image: "!*:latest"
```

**Compliant:**
```yaml
image: nginx:1.25.3
```

**Non-compliant:**
```yaml
image: nginx:latest
image: nginx  # Implicitly :latest
```

## Policy Enforcement Modes

| Mode | Behavior |
|------|----------|
| `Enforce` | Block non-compliant resources |
| `Audit` | Log violations but allow deployment |

All platform policies use `Enforce` mode.

## Testing Policies

**Test rejection:**
```bash
kubectl run test --image=nginx:latest
# Error: Using 'latest' tag is forbidden
```

**Test compliance:**
```bash
kubectl run test --image=nginx:1.25.3 --dry-run=server
# pod/test created (dry run)
```

## Adding New Policies

1. Create ClusterPolicy in `gitops/policies/`
2. Commit and push
3. ArgoCD syncs automatically

## Viewing Policy Reports

```bash
# List policy reports
kubectl get policyreport -A

# Describe violations
kubectl describe policyreport -n <namespace>
```

## Golden Path Compliance

The `standard-service` Helm chart includes compliant defaults:

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000

image:
  tag: "1.25.3"  # Explicit version, not latest
```

Applications using the internal chart automatically comply with all policies.
