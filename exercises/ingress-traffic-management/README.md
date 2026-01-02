# Ingress Traffic Management

Managing multiple applications and traffic routing using K3s and Ingress.

## Overview

| File | Purpose |
|------|---------|
| `Vagrantfile` | Provisions a single-node K3s server with port 80 forwarding |
| `scripts/run.sh` | Installs K3s and deploys the initial applications |
| `scripts/three_app.yaml` | Manifest for three sample Nginx applications |
| `confs/conf.yml` | Alternative manifest using `hello-kubernetes` images |

## Setup

```bash
vagrant up
```

This command provisions a VM named **mradwanS** at `192.168.56.110`.

## Application Deployment

The `scripts/run.sh` script automatically applies `three_app.yaml` during provisioning.

### Sample Apps:
- **App 1**: 1 replica, returns "Hello from app1"
- **App 2**: 3 replicas
- **App 3**: 1 replica

## Traffic Routing

The cluster uses the default K3s Traefik ingress controller. To test routing, you can apply an Ingress resource or use the provided manifests.

### Testing Access:
Since port 80 is forwarded from the host to the VM:
```bash
curl http://localhost
```

## Verification

```bash
vagrant ssh mradwanS
sudo kubectl get pods
sudo kubectl get svc
```

## Requirements

- Vagrant
- VirtualBox
- 1GB RAM available
