# Kustomize Deployment Pattern

## Overview

The platform uses Kustomize for managing custom applications across multiple environments. This approach provides patch-based configuration management without templating complexity, enabling environment-specific customizations while maintaining a shared base configuration.

## Directory Structure

```
gitops/environments/
├── base/
│   ├── backend-api/
│   │   ├── kustomization.yaml
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── configmap.yaml
│   └── sample-flask/
│       ├── kustomization.yaml
│       ├── deployment.yaml
│       └── service.yaml
└── overlays/
    ├── dev/
    │   ├── namespace.yaml
    │   ├── kustomization.yaml
    │   ├── replica-patch.yaml
    │   └── resource-limits-dev.yaml
    ├── staging/
    │   ├── namespace.yaml
    │   └── kustomization.yaml
    └── prod/
        ├── namespace.yaml
        └── kustomization.yaml
```

## Base Configuration

The base directory contains common resources shared across all environments.

### Example: Backend API Base

```yaml
# gitops/environments/base/backend-api/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

commonLabels:
  app: backend-api
  managed-by: kustomize

resources:
- deployment.yaml
- service.yaml
- configmap.yaml
```

```yaml
# gitops/environments/base/backend-api/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-api
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend-api
  template:
    metadata:
      labels:
        app: backend-api
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
      containers:
      - name: podinfo
        image: ghcr.io/stefanprodan/podinfo:6.3.5
        ports:
        - containerPort: 9898
        envFrom:
        - configMapRef:
            name: backend-api-config
        resources:
          requests:
            cpu: 100m
            memory: 64Mi
          limits:
            cpu: 200m
            memory: 128Mi
```

```yaml
# gitops/environments/base/backend-api/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-api
spec:
  type: ClusterIP
  ports:
  - port: 9898
    targetPort: 9898
    protocol: TCP
    name: http
  selector:
    app: backend-api
```

```yaml
# gitops/environments/base/backend-api/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: backend-api-config
data:
  UI_COLOR: "blue"
  LOG_LEVEL: "info"
  API_VERSION: "v1.0.0"
```

## Environment Overlays

Overlays customize base resources for specific environments using patches, ConfigMap generators, and transformers.

### Development Environment

```yaml
# gitops/environments/overlays/dev/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: dev
namePrefix: dev-

resources:
- namespace.yaml
- ../../base/backend-api

replicas:
- name: backend-api
  count: 1

configMapGenerator:
- name: backend-api-config
  behavior: merge
  literals:
  - UI_COLOR=green
  - LOG_LEVEL=debug
  - API_VERSION=v1.0.0-dev

patches:
- path: resource-limits-dev.yaml
  target:
    kind: Deployment
    name: backend-api
```

```yaml
# gitops/environments/overlays/dev/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: dev
  labels:
    environment: development
```

```yaml
# gitops/environments/overlays/dev/resource-limits-dev.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-api
spec:
  template:
    spec:
      containers:
      - name: podinfo
        resources:
          requests:
            cpu: 50m
            memory: 32Mi
          limits:
            cpu: 100m
            memory: 64Mi
```

### Staging Environment

```yaml
# gitops/environments/overlays/staging/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: staging
namePrefix: staging-

resources:
- namespace.yaml
- ../../base/backend-api

replicas:
- name: backend-api
  count: 2

configMapGenerator:
- name: backend-api-config
  behavior: merge
  literals:
  - UI_COLOR=yellow
  - LOG_LEVEL=info
  - API_VERSION=v1.0.0-staging
```

### Production Environment

```yaml
# gitops/environments/overlays/prod/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: production
namePrefix: prod-

resources:
- namespace.yaml
- ../../base/backend-api

replicas:
- name: backend-api
  count: 3

configMapGenerator:
- name: backend-api-config
  behavior: merge
  literals:
  - UI_COLOR=blue
  - LOG_LEVEL=warn
  - API_VERSION=v1.0.0
```

## ArgoCD Integration

Each environment is deployed as a separate ArgoCD Application:

```yaml
# gitops/apps/backend-api-dev.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: backend-api-dev
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/mustafa-wr/Kubernetes-Platform-Engineering.git
    path: Falcon-Platform/gitops/environments/overlays/dev
    targetRevision: main
  destination:
    server: https://kubernetes.default.svc
    namespace: dev
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

```yaml
# gitops/apps/backend-api-staging.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: backend-api-staging
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/mustafa-wr/Kubernetes-Platform-Engineering.git
    path: Falcon-Platform/gitops/environments/overlays/staging
    targetRevision: main
  destination:
    server: https://kubernetes.default.svc
    namespace: staging
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

```yaml
# gitops/apps/backend-api-prod.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: backend-api-prod
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/mustafa-wr/Kubernetes-Platform-Engineering.git
    path: Falcon-Platform/gitops/environments/overlays/prod
    targetRevision: main
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

## Environment Configuration Summary

| Environment | Namespace | Replicas | UI Color | Log Level | CPU Request | Memory Request |
|-------------|-----------|----------|----------|-----------|-------------|----------------|
| Development | dev | 1 | green | debug | 50m | 32Mi |
| Staging | staging | 2 | yellow | info | 100m | 64Mi |
| Production | production | 3 | blue | warn | 200m | 128Mi |

## Advanced Patching with JSON Patch

For precise modifications that preserve base configuration, use JSON patch syntax:

```yaml
# gitops/environments/overlays/dev-flask/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: dev
namePrefix: dev-

resources:
- namespace.yaml
- ../../base/sample-flask

images:
- name: mostafawr/sample-flask-app
  newName: mostafawr/sample-flask-app
  newTag: a0df3df6e301d74c9e4bbee26f02b23df9d9f30a

patches:
- target:
    kind: Deployment
    name: sample-flask
  patch: |-
    - op: add
      path: /spec/template/spec/containers/0/env
      value:
        - name: OTEL_SERVICE_NAME
          value: sample-flask
        - name: OTEL_EXPORTER_OTLP_ENDPOINT
          value: http://otel-collector.monitoring:4318
        - name: OTEL_EXPORTER_OTLP_PROTOCOL
          value: http/protobuf
```

### When to Use JSON Patch

- **Adding environment variables** without overriding existing ones
- **Preserving command/args** from Dockerfile CMD
- **Precise field manipulation** when strategic merge would replace entire structures
- **Array operations** like appending to lists

### JSON Patch Operations

```yaml
# Add operation - creates new field
- op: add
  path: /spec/template/spec/containers/0/env
  value: [...]

# Replace operation - updates existing field
- op: replace
  path: /spec/replicas
  value: 5

# Remove operation - deletes field
- op: remove
  path: /spec/template/spec/containers/0/livenessProbe

# Test operation - validates before applying
- op: test
  path: /spec/replicas
  value: 2
```

## CI/CD Integration

GitHub Actions automatically updates image tags in Kustomize overlays:

```yaml
# .github/workflows/deploy.yaml
name: Build and Deploy

on:
  push:
    branches: [main]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout application repo
        uses: actions/checkout@v3

      - name: Build and push Docker image
        run: |
          docker build -t mostafawr/sample-flask-app:${{ github.sha }} .
          docker push mostafawr/sample-flask-app:${{ github.sha }}

      - name: Checkout platform repo
        uses: actions/checkout@v3
        with:
          repository: mustafa-wr/Kubernetes-Platform-Engineering
          path: platform
          token: ${{ secrets.PLATFORM_REPO_TOKEN }}

      - name: Update Kustomize image
        run: |
          cd platform/Falcon-Platform/gitops/environments/overlays/dev-flask
          kustomize edit set image mostafawr/sample-flask-app=mostafawr/sample-flask-app:${{ github.sha }}

      - name: Commit and push
        run: |
          cd platform
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add .
          git commit -m "chore: update sample-flask image to ${{ github.sha }}"
          git push
```

ArgoCD detects the commit and automatically syncs the new image to the cluster.

## Testing Kustomize Builds

### Preview Generated Manifests

```bash
# Build dev overlay
kubectl kustomize Falcon-Platform/gitops/environments/overlays/dev

# Build staging overlay
kubectl kustomize Falcon-Platform/gitops/environments/overlays/staging

# Build production overlay
kubectl kustomize Falcon-Platform/gitops/environments/overlays/prod
```

### Validate Against Cluster

```bash
# Dry-run server-side validation
kubectl kustomize Falcon-Platform/gitops/environments/overlays/dev | kubectl apply --dry-run=server -f -
```

### Inspect Specific Resources

```bash
# Check deployment configuration
kubectl kustomize Falcon-Platform/gitops/environments/overlays/dev | grep -A 30 "kind: Deployment"

# Verify ConfigMap data
kubectl kustomize Falcon-Platform/gitops/environments/overlays/dev | grep -A 10 "kind: ConfigMap"

# Check resource limits
kubectl kustomize Falcon-Platform/gitops/environments/overlays/dev | grep -A 5 "resources:"
```

## Best Practices

### Base Configuration

1. **Minimal base**: Include only resources common to all environments
2. **No environment-specific values**: Keep base neutral and generic
3. **Sensible defaults**: Use production-safe defaults in base
4. **Complete resources**: Define all required fields in base manifests

### Overlays

1. **Separate namespaces**: Isolate each environment with dedicated namespaces
2. **Use namePrefix**: Prevent resource name collisions across environments
3. **ConfigMap behavior**: Use `behavior: merge` to extend base ConfigMaps
4. **Strategic merge for simple cases**: Use inline YAML patches for straightforward modifications
5. **JSON patch for precision**: Use when strategic merge would replace entire structures
6. **Avoid command/args overrides**: Let Dockerfile CMD handle entrypoints unless necessary

### Organization

1. **One base per application**: Each application gets its own base directory
2. **One overlay per environment**: Separate directories for dev/staging/prod
3. **Clear naming**: Use descriptive names for patch files
4. **Document differences**: Maintain table of environment-specific configurations

### Security

1. **runAsNonRoot**: Enforce in base deployment specs
2. **Resource limits**: Define in all overlays to prevent resource exhaustion
3. **Namespace labels**: Tag namespaces with environment identifiers
4. **Image tags**: Never use `latest`, always specify version or commit SHA

## Troubleshooting

### Common Issues

**Issue**: Kustomize replaces entire container spec

```yaml
# ❌ Wrong - strategic merge replaces container
patches:
- patch: |-
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: app
    spec:
      template:
        spec:
          containers:
          - name: app
            env:
            - name: NEW_VAR
              value: "value"
```

```yaml
# ✓ Correct - JSON patch adds to env array
patches:
- target:
    kind: Deployment
    name: app
  patch: |-
    - op: add
      path: /spec/template/spec/containers/0/env
      value:
      - name: NEW_VAR
        value: "value"
```

**Issue**: Resources not found in overlay

```
Error: unable to find one or more resources
```

**Solution**: Ensure base path is correct and resources exist
```yaml
resources:
- ../../base/backend-api  # Relative path from overlay directory
```

**Issue**: ConfigMap not merging

```yaml
# ❌ Wrong - replaces entire ConfigMap
configMapGenerator:
- name: backend-api-config
  literals:
  - NEW_KEY=value
```

```yaml
# ✓ Correct - merges with base ConfigMap
configMapGenerator:
- name: backend-api-config
  behavior: merge
  literals:
  - NEW_KEY=value
```

**Issue**: Namespace not created

Add explicit namespace resource:
```yaml
resources:
- namespace.yaml
- ../../base/backend-api
```

### Debug Commands

```bash
# Show all resources Kustomize will generate
kubectl kustomize path/to/overlay

# Apply with verbose output
kubectl kustomize path/to/overlay | kubectl apply -f - --v=8

# Diff against cluster
kubectl kustomize path/to/overlay | kubectl diff -f -

# Validate YAML syntax
kubectl kustomize path/to/overlay | kubectl apply --dry-run=client -f -
```

## Comparison with Helm

| Aspect | Helm | Kustomize |
|--------|------|-----------|
| **Approach** | Templating with values | Patch-based overlays |
| **Complexity** | Higher (chart structure, Go templates) | Lower (plain YAML with patches) |
| **Learning Curve** | Steeper (template syntax, functions) | Gentler (YAML knowledge sufficient) |
| **Reusability** | Package and distribute charts | Share base configurations via Git |
| **Versioning** | Chart versions in registry | Git commits and branches |
| **Dependencies** | Managed via Chart.yaml | Not natively supported |
| **Conditionals** | Template logic and functions | Not supported (use multiple overlays) |
| **Values** | Centralized values.yaml | Distributed across overlays |
| **Best For** | Infrastructure, third-party apps | Custom apps, multi-environment configs |

Both tools coexist in the platform:
- **Helm**: Infrastructure layer (Prometheus, Grafana, Kyverno, Vault)
- **Kustomize**: Application layer (custom microservices, multi-env deployments)

## Reference

- [Kustomize Official Documentation](https://kustomize.io/)
- [Kubernetes Kustomization API](https://kubectl.docs.kubernetes.io/references/kustomize/)
- [ArgoCD Kustomize Support](https://argo-cd.readthedocs.io/en/stable/user-guide/kustomize/)
