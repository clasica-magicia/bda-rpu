#!/bin/bash
set -euo pipefail

DOMAIN="${1:-local}"
CT_ID="${CT_ID:-101}"
HOSTNAME="mail.${DOMAIN}"
MEMORY="${MEMORY:-2048}"
SWAP="${SWAP:-1024}"
DISK="${DISK:-32}"
STORAGE="${STORAGE:-local-lvm}"
TEMPLATE="${TEMPLATE:-ubuntu-22.04-standard}"

if ! command -v pct >/dev/null 2>&1; then
    echo "This script requires a Proxmox host with pct available."
    exit 1
fi

if pct status "$CT_ID" >/dev/null 2>&1; then
    echo "Container $CT_ID already exists."
    exit 0
fi

pct create "$CT_ID" "$TEMPLATE" --hostname "$HOSTNAME" --memory "$MEMORY" --swap "$SWAP" --rootfs "$STORAGE:${DISK}" --features nesting=1 --net0 name=eth0,bridge=vmbr0,ip=192.168.100.101/24,gw=192.168.100.1 --ostype ubuntu --unprivileged 1
pct start "$CT_ID"

sleep 15
pct exec "$CT_ID" -- bash -lc "apt-get update -y && apt-get install -y curl wget vim git postfix dovecot-imapd dovecot-pop3d certbot python3-certbot-nginx"

cat <<EOF
Mail server container created successfully.
Access via: https://mail.${DOMAIN}
Internal IP: 192.168.100.101
EOF
