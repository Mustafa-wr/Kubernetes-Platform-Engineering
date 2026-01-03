# GitOps Implementation

## Overview

The platform uses ArgoCD with the App of Apps pattern for declarative, Git-based application management.

## ArgoCD Installation

```bash
# Using Makefile
make gitops-bootstrap

# Or manually
cd gitops
./bootstrap_argocd.sh
```

The bootstrap script:
1. Adds ArgoCD Helm repository
2. Installs ArgoCD with LoadBalancer service
3. Outputs admin credentials

## Access ArgoCD

```bash
# Get LoadBalancer IP
kubectl get svc argocd-server -n argocd

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## App of Apps Pattern

Single entry point (`root.yaml`) manages all platform applications:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: falcon-root
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/mustafa-wr/Kubernetes-Platform-Engineering.git
    path: Falcon-Platform/gitops/apps
    targetRevision: main
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

## Deploy Applications

```bash
# Deploy everything
kubectl apply -f gitops/root.yaml

# Or using Makefile
make gitops-deploy
```

## Application Structure

### apps/ Directory

Each file defines an ArgoCD Application:

| File | Application | Source |
|------|-------------|--------|
| core.yaml | Platform infrastructure | Internal manifests |
| ingress-nginx.yaml | Ingress controller | Helm chart |
| kyverno.yaml | Policy engine | Helm chart |
| monitoring.yaml | Prometheus + Grafana | Helm chart |
| backend-api.yaml | Tenant application | Internal Helm chart |
| backend-db.yaml | PostgreSQL | Bitnami Helm chart |
| podinfo.yaml | Demo application | Helm chart |
| guest.yaml | Guestbook | External Git repo |
| policies.yaml | Kyverno policies | Internal manifests |
| tenants.yaml | Tenant namespaces | Internal manifests |

### core/ Directory

Platform infrastructure resources:
- `system.yaml` - PriorityClasses, namespaces
- `dashboard.yaml` - Grafana dashboard ConfigMaps
- `vault.yaml` - HashiCorp Vault deployment

### policies/ Directory

Kyverno ClusterPolicies:
- `disallow-root.yaml` - Block root containers
- `dissallow-latest-tag.yaml` - Block :latest images

### tenants/ Directory

Tenant configurations:
- `backend.yaml` - Backend team namespace and ResourceQuota

## Sync Behavior

All applications configured with:

```yaml
syncPolicy:
  automated:
    prune: true      # Remove resources deleted from Git
    selfHeal: true   # Revert manual changes
  syncOptions:
    - CreateNamespace=true
```

## Adding New Applications

1. Create Application manifest in `gitops/apps/`
2. Reference internal chart or external Helm repository
3. Commit and push to Git
4. ArgoCD syncs automatically

Example:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/mustafa-wr/Kubernetes-Platform-Engineering.git
    path: Falcon-Platform/internal-charts/standard-service
    targetRevision: main
    helm:
      values: |
        replicaCount: 2
        image: my-image:1.0.0
  destination:
    server: https://kubernetes.default.svc
    namespace: team-backend
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

## Monitoring Sync Status

```bash
# List all applications
kubectl get applications -n argocd

# Check specific application
kubectl describe application falcon-root -n argocd

# Using Makefile
make status
```
