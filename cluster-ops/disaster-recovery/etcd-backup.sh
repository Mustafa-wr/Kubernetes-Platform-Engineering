#!/bin/bash
# Automated Backup Script for Etcd
# Usage: ./etcd-backup.sh <destination-path>
sudo ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot save "$1/snapshot-$(date +%Y-%m-%d).db"