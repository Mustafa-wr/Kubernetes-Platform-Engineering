# GitOps Delivery with ArgoCD

Automated application delivery using ArgoCD on a local k3d cluster.

## Overview

| File | Purpose |
|------|---------|
| `scripts/steps.sh` | Installs Docker, kubectl, k3d, and ArgoCD CLI |
| `scripts/k-setup.sh` | Provisions k3d cluster and installs ArgoCD/Ingress NGINX |
| `confs/synced/conf.yml` | Sample application (Deployment, Service, Ingress) |
| `confs/refresher.yml` | Automated sync loop for the ArgoCD application |

## Setup

### 1. Prerequisites
Install the necessary tools on your host machine:
```bash
sudo ./scripts/steps.sh
```
*Note: This script will prompt for a reboot to finalize Docker group changes.*

### 2. Cluster Provisioning
Create the k3d cluster and install ArgoCD:
```bash
./scripts/k-setup.sh
```
This script:
- Creates a cluster named `p3cluster`
- Maps port `30080` for ArgoCD UI and `8888` for the application
- Installs ArgoCD in the `argocd` namespace
- Installs Ingress NGINX controller

## ArgoCD Access

- **URL:** `https://localhost:30080`
- **Username:** `admin`
- **Password:** Retrieve using:
  ```bash
  kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d
  ```

## Application Deployment

1. Create the ArgoCD Application (via UI or CLI) pointing to the `confs/synced` directory.
2. The sample application runs `wil42/playground:v1` on port `8888`.
3. Access the application at `http://localhost:8888`.

## Automated Sync (Refresher)

To simulate a continuous sync loop or force updates every 10 seconds:
```bash
kubectl apply -f confs/refresher.yml
```
*Note: Ensure the `ARGOCD_PASSWORD` environment variable is correctly set in the manifest or passed during application.*

## Requirements

- Linux environment (Ubuntu recommended)
- Docker
- k3d
- kubectl
