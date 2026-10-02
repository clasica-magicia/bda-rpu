#!/bin/bash
set -euo pipefail

CT_ID="${CT_ID:-103}"
MEMORY="${MEMORY:-2048}"
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

pct create "$CT_ID" "$TEMPLATE" --hostname n8n --memory "$MEMORY" --rootfs "$STORAGE:${DISK}" --features nesting=1 --net0 name=eth0,bridge=vmbr0,ip=192.168.100.103/24,gw=192.168.100.1 --ostype ubuntu --unprivileged 1
pct start "$CT_ID"

sleep 15
pct exec "$CT_ID" -- bash -lc "apt-get update -y && apt-get install -y curl ca-certificates && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && apt-get install -y nodejs && npm install -g n8n"

cat <<EOF
n8n container created successfully.
Internal IP: 192.168.100.103
Access: http://192.168.100.103:5678
EOF
