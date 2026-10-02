#!/bin/bash
set -euo pipefail

CT_ID="${CT_ID:-105}"
MEMORY="${MEMORY:-1024}"
STORAGE="${STORAGE:-local-lvm}"
DISK="${DISK:-32}"
TEMPLATE="${TEMPLATE:-ubuntu-22.04-standard}"

if ! command -v pct >/dev/null 2>&1; then
    echo "This script requires a Proxmox host with pct available."
    exit 1
fi

if pct status "$CT_ID" >/dev/null 2>&1; then
    echo "Container $CT_ID already exists."
    exit 0
fi

pct create "$CT_ID" "$TEMPLATE" --hostname restic --memory "$MEMORY" --rootfs "$STORAGE:${DISK}" --features nesting=1 --net0 name=eth0,bridge=vmbr0,ip=192.168.100.105/24,gw=192.168.100.1 --ostype ubuntu --unprivileged 1
pct start "$CT_ID"

sleep 15
pct exec "$CT_ID" -- bash -lc "apt-get update -y && apt-get install -y restic openssh-client"

cat <<EOF
Restic backup container created successfully.
Internal IP: 192.168.100.105
Use the maintenance scripts to initialize and rotate backups.
EOF
