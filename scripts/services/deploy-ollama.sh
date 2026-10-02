#!/bin/bash
set -euo pipefail

CT_ID="${CT_ID:-107}"
MEMORY="${MEMORY:-8192}"
STORAGE="${STORAGE:-local-lvm}"
DISK="${DISK:-96}"
TEMPLATE="${TEMPLATE:-ubuntu-22.04-standard}"

if ! command -v pct >/dev/null 2>&1; then
    echo "This script requires a Proxmox host with pct available."
    exit 1
fi

if pct status "$CT_ID" >/dev/null 2>&1; then
    echo "Container $CT_ID already exists."
    exit 0
fi

pct create "$CT_ID" "$TEMPLATE" --hostname ollama --memory "$MEMORY" --rootfs "$STORAGE:${DISK}" --features nesting=1 --net0 name=eth0,bridge=vmbr0,ip=192.168.100.107/24,gw=192.168.100.1 --ostype ubuntu --unprivileged 1
pct start "$CT_ID"

sleep 15
pct exec "$CT_ID" -- bash -lc "apt-get update -y && apt-get install -y curl ca-certificates && curl -fsSL https://ollama.com/install.sh | sh"

cat <<EOF
Ollama container created successfully.
Internal IP: 192.168.100.107
API: http://192.168.100.107:11434
Open WebUI: http://192.168.100.107:8080
EOF
