# Etcd Disaster Recovery

Backup and restore scripts for Kubernetes etcd datastore.

## Overview

| Script | Purpose |
|--------|---------|
| `etcdctl.sh` | Installs etcdctl v3.5.15 binary |
| `etcd-backup.sh` | Creates a point-in-time snapshot of etcd |
| `etcd-restore.sh` | Restores etcd from a snapshot file |

## Setup

```bash
vagrant up
vagrant ssh kube-control-plane
```

The Vagrantfile provisions a control-plane node with etcdctl pre-installed.

## Backup

```bash
sudo ./etcd-backup.sh /tmp
```

Output: `/tmp/snapshot-YYYY-MM-DD.db`

The script uses the etcd certificates from `/etc/kubernetes/pki/etcd/` to authenticate.

## Restore

```bash
sudo ./etcd-restore.sh /tmp/snapshot-YYYY-MM-DD.db
```

Restore process:
1. Stops kubelet
2. Moves static pod manifests to prevent API server interference
3. Backs up current etcd data directory
4. Restores snapshot to `/var/lib/etcd`
5. Fixes ownership permissions
6. Restores manifests and restarts kubelet

## Requirements

- Kubernetes cluster with etcd running as static pod
- Root/sudo access
- etcdctl binary (installed via `etcdctl.sh`)
