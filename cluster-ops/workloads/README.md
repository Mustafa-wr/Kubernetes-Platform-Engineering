# Kubernetes Workload Management

Application deployment, scaling, and rollback with zero downtime.

## Overview

| File | Purpose |
|------|---------|
| `production-deployment.yaml` | Reference app deployment with rolling update strategy |
| `scaling-policy.yaml` | HorizontalPodAutoscaler for CPU-based autoscaling |
| `pdb.yaml` | PodDisruptionBudget to ensure availability during maintenance |

## Setup

```bash
vagrant up
vagrant ssh kube-control-plane
```

## Deployment

```bash
kubectl apply -f production-deployment.yaml
kubectl get deployment reference-app
```

Expected: 3/3 replicas running with nginx:1.23.4-alpine

## Rolling Update

```bash
# Update image version
kubectl set image deployment/reference-app app=nginx:1.24.0-alpine

# Record change reason for history
kubectl annotate deployment reference-app kubernetes.io/change-cause="Upgrade to nginx 1.24.0"

# Monitor rollout progress
kubectl rollout status deployment/reference-app
```

Rolling update brings up new pods gradually while terminating old ones, ensuring zero downtime.

## Scaling

Manual scaling:
```bash
kubectl scale deployment reference-app --replicas=5
```

Autoscaling with HPA:
```bash
kubectl apply -f scaling-policy.yaml
```

HPA scales between 3-10 replicas based on 70% CPU utilization target.

## High Availability (PDB)

```bash
kubectl apply -f pdb.yaml
```

The PDB ensures at least 2 replicas remain available during voluntary disruptions (e.g., node drains).

## Rollback (Manual)

View revision history:
```bash
kubectl rollout history deployment/reference-app
```

Manually revert to previous version:
```bash
kubectl rollout undo deployment/reference-app --to-revision=1
```

Verify rollback:
```bash
kubectl describe deployment reference-app | grep Image
```

Note: Rollback is a manual operation requiring explicit administrator intervention.

## Deployment Strategies

- **RollingUpdate** (default): Gradually replaces pods, zero downtime, mixed versions during transition
- **Recreate**: Terminates all pods before creating new ones, use for breaking changes

## Requirements

- Kubernetes cluster with metrics-server (for HPA)
- kubectl with admin access
