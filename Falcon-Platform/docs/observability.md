# Observability

## Overview

The platform includes Prometheus for metrics collection and Grafana for visualization.

## Installation

Deployed via ArgoCD using kube-prometheus-stack:

```yaml
# gitops/apps/monitoring.yaml
source:
  repoURL: https://prometheus-community.github.io/helm-charts
  chart: kube-prometheus-stack
  targetRevision: 56.6.2
```

## Access Grafana

```bash
make grafana-access
# http://localhost:3000
# Username: admin
# Password: admin
```

Or manually:
```bash
kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80
```

## Components

### Prometheus

Configuration:
```yaml
prometheus:
  prometheusSpec:
    resources:
      requests:
        memory: "400Mi"
        cpu: "200m"
      limits:
        memory: "800Mi"
        cpu: "500m"
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: "standard"
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 2Gi
```

### Grafana Dashboards

Pre-configured dashboards deployed via ConfigMap:

```yaml
# gitops/core/dashboard.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: podinfo-dashboard
  namespace: monitoring
  labels:
    grafana_dashboard: "1"
data:
  podinfo-health.json: |-
    {
      "title": "Podinfo Health Overview",
      "panels": [...]
    }
```

### Included Dashboards

1. **Podinfo Health Overview**
   - CPU usage per pod
   - Memory usage per pod

2. **Default kube-prometheus-stack dashboards**
   - Kubernetes cluster overview
   - Node metrics
   - Pod metrics
   - Namespace resources

## Querying Metrics

Access Prometheus directly:
```bash
kubectl port-forward svc/monitoring-kube-prometheus-prometheus -n monitoring 9090:9090
```

Example PromQL queries:

```promql
# CPU usage for podinfo
sum(node_namespace_pod_container:container_cpu_usage_seconds_total:sum_irate{namespace='default', pod=~'podinfo.*'}) by (pod)

# Memory usage for podinfo
sum(container_memory_working_set_bytes{namespace='default', pod=~'podinfo.*'}) by (pod)

# All pods not running
kube_pod_status_phase{phase!="Running"}
```

## Alerting

kube-prometheus-stack includes default alerting rules for:
- Node availability
- Pod health
- Resource usage thresholds
- Kubernetes component health

## Adding Custom Dashboards

1. Create ConfigMap with `grafana_dashboard: "1"` label
2. Add to `gitops/core/`
3. Commit and push
4. Dashboard appears automatically in Grafana

## Resource Constraints

The monitoring stack is configured for demo environments with limited resources. Production deployments should increase:
- Prometheus memory and storage
- Retention period
- Replica counts
