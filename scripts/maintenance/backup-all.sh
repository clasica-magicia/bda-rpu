#!/bin/bash
set -euo pipefail

RESTIC_REPO="${RESTIC_REPO:-/var/backups/restic}"
RESTIC_PASSWORD="${RESTIC_PASSWORD:-change-me}"

mkdir -p "$RESTIC_REPO"
export RESTIC_PASSWORD

if ! command -v restic >/dev/null 2>&1; then
    echo "restic is not installed."
    exit 1
fi

if ! restic snapshots >/dev/null 2>&1; then
    restic init -r "$RESTIC_REPO" >/dev/null 2>&1 || true
fi

restic backup /etc /var/www /root/bda-rpu --tag bda --host "$(hostname)" -r "$RESTIC_REPO" >/var/log/bda-backup-run.log 2>&1 || {
    echo "Backup failed" >&2
    exit 1
}

echo "Backup completed successfully"
