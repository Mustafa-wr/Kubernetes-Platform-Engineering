# Observability

## Overview

The platform provides comprehensive observability through multiple components:

- **Prometheus**: Metrics collection and storage
- **Grafana**: Unified visualization and dashboards
- **OpenTelemetry Collector**: Distributed tracing aggregation
- **Grafana Tempo**: Trace storage backend

This stack enables monitoring of system health, application performance, and distributed request tracing across the platform.

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

## Distributed Tracing

### Architecture

The platform implements distributed tracing using OpenTelemetry and Grafana Tempo:

```
Application → OpenTelemetry Collector → Grafana Tempo → Grafana Query
(Auto-instrumented)    (OTLP Receiver)      (Storage)     (Visualization)
```

### OpenTelemetry Collector

Deployed as a centralized trace aggregation service in the monitoring namespace.

**Configuration**:
```yaml
# gitops/apps/otel-collector.yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

processors:
  batch:
    timeout: 10s

exporters:
  otlp/tempo:
    endpoint: tempo.monitoring:4317
    tls:
      insecure: true
  logging:
    loglevel: debug

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch]
      exporters: [otlp/tempo, logging]
    metrics:
      receivers: [otlp]
      processors: [batch]
      exporters: [prometheus, logging]
```

**Service Endpoints**:
- OTLP gRPC: `otel-collector.monitoring:4317`
- OTLP HTTP: `otel-collector.monitoring:4318`
- Prometheus metrics: `otel-collector.monitoring:8889`

### Grafana Tempo

Backend storage for distributed traces with OTLP ingestion support.

**Configuration**:
```yaml
# gitops/apps/tempo.yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

storage:
  trace:
    backend: local
    local:
      path: /var/tempo
```

**Service Endpoints**:
- Query API: `tempo.monitoring:3200`
- OTLP gRPC: `tempo.monitoring:4317`
- OTLP HTTP: `tempo.monitoring:4318`

**Grafana Datasource**:

Tempo is automatically configured as a datasource in Grafana:
```yaml
# gitops/core/tempo-datasource.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: tempo-datasource
  namespace: monitoring
  labels:
    grafana_datasource: "1"
data:
  tempo-datasource.yaml: |-
    apiVersion: 1
    datasources:
      - name: Tempo
        type: tempo
        access: proxy
        url: http://tempo.monitoring:3200
        uid: tempo
        isDefault: false
        editable: false
```

### Application Instrumentation

Applications are instrumented using OpenTelemetry auto-instrumentation.

**Example: Python Flask Application**

1. **Dependencies** (requirements.txt):
```
opentelemetry-distro
opentelemetry-exporter-otlp
opentelemetry-instrumentation-flask
```

2. **Dockerfile**:
```dockerfile
CMD ["opentelemetry-instrument", \
     "--traces_exporter", "otlp", \
     "--metrics_exporter", "otlp", \
     "--service_name", "sample-flask-app", \
     "gunicorn", "--bind", "0.0.0.0:8080", "--workers", "2", "app:app"]
```

3. **Environment Variables** (Kustomize overlay):
```yaml
env:
- name: OTEL_SERVICE_NAME
  value: sample-flask
- name: OTEL_EXPORTER_OTLP_ENDPOINT
  value: http://otel-collector.monitoring:4318
- name: OTEL_EXPORTER_OTLP_PROTOCOL
  value: http/protobuf
```

The `opentelemetry-instrument` command wraps the application process and automatically instruments frameworks like Flask, generating traces for each HTTP request without code changes.

### Viewing Traces in Grafana

1. **Access Grafana**:
```bash
kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80
# Navigate to http://localhost:3000
# Login: admin / prom-operator
```

2. **Query Traces**:
   - Navigate to **Explore** in the left sidebar
   - Select **Tempo** datasource from the dropdown
   - Use the **Search** tab to browse recent traces
   - Use **TraceQL** tab for advanced queries:
     ```
     # All traces
     {}
     
     # Filter by service
     {resource.service.name="sample-flask"}
     
     # Filter by duration
     {duration > 100ms}
     
     # Search by trace ID
     <trace-id>
     ```

3. **Trace Details**:
   Each trace displays:
   - Service name and operation
   - Request duration and timestamps
   - Span hierarchy and relationships
   - HTTP method, status code, and target URL
   - Resource attributes and metadata

### Trace Data Flow

1. Application receives HTTP request
2. OpenTelemetry SDK generates span with trace context
3. Span exported via OTLP protocol to OTel Collector endpoint
4. OTel Collector batches traces and forwards to Tempo
5. Tempo stores traces in local storage backend
6. Grafana queries Tempo API to retrieve and visualize traces

### Multi-Environment Setup

For Kustomize-based applications with multiple environments:

**Base Deployment** (no command/args override):
```yaml
# gitops/environments/base/sample-flask/deployment.yaml
spec:
  containers:
  - name: sample-flask
    image: mostafawr/sample-flask-app:latest
    # No command/args - uses Dockerfile CMD
    ports:
    - containerPort: 8080
```

**Environment Overlay** (adds OTel configuration):
```yaml
# gitops/environments/overlays/dev-flask/kustomization.yaml
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

This approach preserves the Dockerfile CMD with OpenTelemetry instrumentation while allowing environment-specific configuration via Kustomize patches.

### Troubleshooting

**Verify OTel Collector is receiving traces**:
```bash
kubectl logs -n monitoring deployment/otel-collector | grep "Span #"
```

**Check Tempo is running**:
```bash
kubectl get pods -n monitoring -l app=tempo
```

**Test application trace generation**:
```bash
# Port forward to application
kubectl port-forward -n dev svc/dev-sample-flask 8080:8080

# Generate traffic
for i in {1..10}; do curl http://localhost:8080/; done

# Check OTel Collector logs for new trace IDs
kubectl logs -n monitoring deployment/otel-collector --tail=50 | grep "Trace ID"
```

**Common Issues**:

- **No traces in Grafana**: Verify environment variables are set correctly and OTel Collector is reachable from application pods
- **Connection refused**: Check service names and namespaces in OTLP endpoint URLs
- **Instrumentation not working**: Ensure Dockerfile CMD uses `opentelemetry-instrument` wrapper and no command/args override in deployment spec

### Performance Considerations

- **Sampling**: Production deployments should implement trace sampling to reduce overhead
- **Batch Processing**: OTel Collector batches traces with 10s timeout before export
- **Storage**: Tempo uses local storage suitable for demo environments; production requires distributed storage backends
- **Resource Limits**: OTel Collector configured with 200m CPU and 256Mi memory limits for demo workloads

### Security

- **TLS**: Demo configuration uses insecure gRPC connections between components
- **Authentication**: No authentication required for OTLP endpoints in demo setup
- **Production**: Enable mTLS between services and implement authentication for production deployments
