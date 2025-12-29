# Kubernetes Workload Management

Application deployment, scaling, and rollback with zero downtime.

## Overview

| File | Purpose |
|------|---------|
| `production-deployment.yaml` | Nginx deployment with rolling update strategy |
| `scaling-policy.yaml` | HorizontalPodAutoscaler for CPU-based autoscaling |

## Setup

```bash
vagrant up
vagrant ssh kube-control-plane
```

## Deployment

```bash
kubectl apply -f production-deployment.yaml
kubectl get deployment nginx
```

Expected: 3/3 replicas running with nginx:1.23.0

## Rolling Update

```bash
# Update image version
kubectl set image deployment/nginx nginx=nginx:1.23.4

# Record change reason for history
kubectl annotate deployment nginx kubernetes.io/change-cause="Patch version update"

# Monitor rollout progress
kubectl rollout status deployment/nginx
```

Rolling update brings up new pods gradually while terminating old ones, ensuring zero downtime.

## Scaling

Manual scaling:
```bash
kubectl scale deployment nginx --replicas=5
```

Autoscaling with HPA:
```bash
kubectl apply -f scaling-policy.yaml
```

HPA scales between 3-10 replicas based on 50% CPU utilization target.

## Rollback (Manual)

View revision history:
```bash
kubectl rollout history deployment/nginx
```

Manually revert to previous version:
```bash
kubectl rollout undo deployment/nginx --to-revision=1
```

Verify rollback:
```bash
kubectl describe deployment nginx | grep Image
```

Note: Rollback is a manual operation requiring explicit administrator intervention.

## Deployment Strategies

- **RollingUpdate** (default): Gradually replaces pods, zero downtime, mixed versions during transition
- **Recreate**: Terminates all pods before creating new ones, use for breaking changes

## Requirements

- Kubernetes cluster with metrics-server (for HPA)
- kubectl with admin access
