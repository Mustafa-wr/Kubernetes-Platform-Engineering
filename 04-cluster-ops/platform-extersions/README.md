# Kubernetes Custom Resource Definitions

Extending Kubernetes API with custom Backup resources.

## Overview

| File | Purpose |
|------|---------|
| `backup-crd.yaml` | Defines CustomResourceDefinition for scheduled backups |
| `backup-sample.yaml` | Sample Backup resource instance |

## Setup

```bash
vagrant up
vagrant ssh kube-control-plane
```

The Vagrantfile provisions a control-plane node with kubectl configured.

## Installing the CRD

```bash
kubectl apply -f backup-crd.yaml
```

This registers a new API resource type `backups.example.com/v1` with the cluster.

## Creating Backup Resources

```bash
kubectl apply -f backup-sample.yaml
```

The sample creates a backup for nginx pod at `/usr/local/nginx` with daily schedule.

## Viewing Custom Resources

```bash
# List all backups
kubectl get backups

# Short form
kubectl get bk

# Detailed view
kubectl describe backup nginx-backup
```

Custom columns displayed:
- Schedule (cron expression)
- Target_Pod (pod name)
- Path (backup directory)
- Age (creation timestamp)

## Resource Schema

Required fields:
- `cronExpression`: Backup schedule in cron format
- `podName`: Target pod name
- `path`: Directory path to backup

## Requirements

- Kubernetes cluster with API extensions enabled
- kubectl with admin access
