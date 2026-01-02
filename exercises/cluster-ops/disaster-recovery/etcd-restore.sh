#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status

# usage: ./etcd-restore.sh /path/to/snapshot.db

SNAPSHOT_PATH=$1
DATA_DIR_BACKUP="/var/lib/etcd-backup-$(date +%s)"
ETCD_DATA_DIR="/var/lib/etcd"

if [ -z "$SNAPSHOT_PATH" ]; then
    echo "Error: No snapshot path provided."
    echo "Usage: $0 <path-to-snapshot>"
    exit 1
fi

if [ ! -f "$SNAPSHOT_PATH" ]; then
    echo "Error: Snapshot file not found at $SNAPSHOT_PATH"
    exit 1
fi

echo "⚠️  STARTING ETCD RESTORE PROCESS..."

# 1. Stop the Kubernetes components to release the lock on etcd
echo "1. Stopping kubelet..."
systemctl stop kubelet

# 2. Stop the API Server (and other static pods) by moving manifests
# This is a common pattern to ensure Etcd stops if it's running as a static pod
echo "2. Temporarily moving static pod manifests..."
mkdir -p /etc/kubernetes/manifests_backup
mv /etc/kubernetes/manifests/*.yaml /etc/kubernetes/manifests_backup/

# 3. Backup the existing data directory (Safety Net)
echo "3. Backing up current etcd data to $DATA_DIR_BACKUP..."
mv $ETCD_DATA_DIR $DATA_DIR_BACKUP

# 4. Perform the Restore
# Note: We verify the hash to ensure integrity
echo "4. Restoring snapshot..."
ETCDCTL_API=3 etcdctl snapshot restore "$SNAPSHOT_PATH" \
  --data-dir="$ETCD_DATA_DIR"

# 5. Restore Permissions
# The new directory is owned by root by default; etcd user needs access
echo "5. Fixing permissions..."
chown -R etcd:etcd $ETCD_DATA_DIR 2>/dev/null || chown -R 1001:1001 $ETCD_DATA_DIR

# 6. Restart components
echo "6. Restoring static pod manifests..."
mv /etc/kubernetes/manifests_backup/*.yaml /etc/kubernetes/manifests/

echo "7. Starting kubelet..."
systemctl start kubelet

echo "✅ Restore process complete. It may take a minute for the API server to come back online."