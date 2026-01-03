# Multi-Tenancy

## Overview

The platform provides namespace-based isolation with resource quotas for team workloads.

## Tenant Structure

```
team-backend/
├── Namespace (with labels)
├── ResourceQuota
├── Backend API (Deployment, Service)
└── PostgreSQL (StatefulSet, Service, PVC)
```

## Tenant Configuration

```yaml
# gitops/tenants/backend.yaml

# Namespace
apiVersion: v1
kind: Namespace
metadata:
  name: team-backend
  labels:
    falcon-tenant: backend

---
# Resource Quota
apiVersion: v1
kind: ResourceQuota
metadata:
  name: backend-quota
  namespace: team-backend
spec:
  hard:
    requests.cpu: "1"
    requests.memory: 1Gi
    limits.cpu: "2"
    limits.memory: 2Gi
    pods: "10"
```

## Resource Limits

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 1 core | 2 cores |
| Memory | 1Gi | 2Gi |
| Pods | - | 10 |

## Adding a New Tenant

1. Create namespace configuration in `gitops/tenants/`:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: team-frontend
  labels:
    falcon-tenant: frontend
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: frontend-quota
  namespace: team-frontend
spec:
  hard:
    requests.cpu: "2"
    requests.memory: 2Gi
    limits.cpu: "4"
    limits.memory: 4Gi
    pods: "20"
```

2. Add tenant application in `gitops/apps/tenants.yaml` or create separate file

3. Update Vault role if secrets access needed:

```hcl
resource "vault_kubernetes_auth_backend_role" "frontend" {
  role_name                        = "frontend-role"
  bound_service_account_names      = ["default"]
  bound_service_account_namespaces = ["team-frontend"]
  token_policies                   = ["internal-app"]
}
```

## Deploying to Tenant Namespace

Applications target tenant namespaces:

```yaml
# gitops/apps/backend-api.yaml
destination:
  server: https://kubernetes.default.svc
  namespace: team-backend
```

## Quota Enforcement

Kubernetes rejects pods exceeding quota:

```bash
kubectl run test --image=nginx -n team-backend --dry-run=server
# Error: exceeded quota
```

Check quota usage:
```bash
kubectl describe resourcequota -n team-backend
```

## Network Isolation

Calico network policies can restrict cross-namespace traffic:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-cross-namespace
  namespace: team-backend
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          falcon-tenant: backend
```

## Application Generator

The `create-app.sh` wizard prompts for team assignment:

```
Available Teams: backend, frontend, data
Which team owns this app? (default: backend): backend
```

Sets the destination namespace automatically.
