# Developer Guide

## Onboarding Applications

### Using the Application Generator

The fastest way to deploy a new application:

```bash
cd Falcon-Platform
make create-app
```

The wizard prompts for:
1. Application name
2. Docker image
3. Replica count
4. Team/tenant
5. Vault integration (optional)
6. Environment variables

Generates a complete ArgoCD Application manifest.

### Manual Application Creation

1. Create Application manifest in `gitops/apps/`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-service
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
        image: my-registry/my-image:1.0.0
        service:
          port: 8080
  destination:
    server: https://kubernetes.default.svc
    namespace: team-backend
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

2. Commit and push:
```bash
git add gitops/apps/my-service.yaml
git commit -m "feat: add my-service"
git push
```

3. ArgoCD syncs automatically

## Standard Service Chart

The internal Helm chart at `internal-charts/standard-service/` provides:

### Default Values

```yaml
replicaCount: 1

image:
  repository: nginx
  tag: "1.25.3"
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80

resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 100m
    memory: 128Mi

securityContext:
  runAsNonRoot: true
  runAsUser: 1000
```

### Overriding Values

```yaml
helm:
  values: |
    replicaCount: 3
    image: ghcr.io/stefanprodan/podinfo:6.3.5
    service:
      port: 9898
    resources:
      limits:
        cpu: 200m
        memory: 256Mi
```

## Policy Compliance

The standard-service chart includes compliant defaults:
- Non-root user (required by `disallow-root-user` policy)
- Explicit image tag (required by `disallow-latest-tag` policy)
- Resource limits

## Adding Vault Secrets

Add annotations for Vault Agent injection:

```yaml
helm:
  values: |
    podAnnotations:
      vault.hashicorp.com/agent-inject: "true"
      vault.hashicorp.com/role: "backend-role"
      vault.hashicorp.com/agent-inject-secret-config.txt: "secret/data/db-creds"
```

Secrets are mounted at `/vault/secrets/config.txt`.

## Environment Variables

```yaml
helm:
  values: |
    env:
      - name: LOG_LEVEL
        value: "info"
      - name: FEATURE_FLAG
        value: "enabled"
```

## Deployment Workflow

```
Developer          Git Repo           ArgoCD            Cluster
    │                  │                 │                 │
    ├─ create app.yaml │                 │                 │
    ├─ git push ───────>                 │                 │
    │                  │                 │                 │
    │                  ├─ webhook ───────>                 │
    │                  │                 │                 │
    │                  │                 ├─ sync ──────────>
    │                  │                 │                 │
    │                  │                 │   create pods   │
    │                  │                 <─ status ────────┤
    │                  │                 │                 │
```

## Monitoring Your Application

1. Check ArgoCD status:
```bash
kubectl get application my-service -n argocd
```

2. View pods:
```bash
kubectl get pods -n team-backend -l app=my-service
```

3. Access Grafana for metrics:
```bash
make grafana-access
```

## Troubleshooting

### Sync Failed

```bash
kubectl describe application my-service -n argocd
```

### Policy Rejection

```bash
kubectl get events -n team-backend
# Look for Kyverno admission errors
```

### Resource Quota Exceeded

```bash
kubectl describe resourcequota -n team-backend
```
