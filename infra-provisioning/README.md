# Infrastructure Provisioning

Automated multi-node K3s cluster setup using Vagrant and VirtualBox.

## Overview

| File | Purpose |
|------|---------|
| `Vagrantfile` | Defines server and worker VMs (Debian Bullseye) |
| `scripts/provision_server.sh` | Installs K3s server and exports join token |
| `scripts/provision_worker.sh` | Installs K3s agent and joins the cluster |

## Setup

```bash
vagrant up
```

This command provisions two virtual machines:
1. **mradwanS** (Server): `192.168.56.110`
2. **mradwanSW** (Worker): `192.168.56.111`

## Provisioning Logic

### Server Node
- Installs K3s with `--bind-address=192.168.56.110`
- Configures Flannel to use `eth1` for cross-node communication
- Saves the node token to `confs/server_token.txt` for the worker to use
- Copies `k3s.yaml` (kubeconfig) to the shared `confs/` directory

### Worker Node
- Waits for the server token to be available in the shared folder
- Joins the cluster using `K3S_URL="https://192.168.56.110:6443"`
- Cleans up the `confs/` directory after successful join

## Verification

```bash
vagrant ssh mradwanS
sudo kubectl get nodes
```

Expected output:
```text
NAME        STATUS   ROLES                  AGE   VERSION
mradwanS    Ready    control-plane,master   1m    v1.X.X
mradwanSW   Ready    <none>                 30s   v1.X.X
```

## Requirements

- Vagrant
- VirtualBox
- 2GB RAM available (1GB per VM)
