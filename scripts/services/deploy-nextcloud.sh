#!/bin/bash
set -euo pipefail

CT_ID="${CT_ID:-102}"
MEMORY="${MEMORY:-4096}"
STORAGE="${STORAGE:-local-lvm}"
DISK="${DISK:-64}"
TEMPLATE="${TEMPLATE:-ubuntu-22.04-standard}"

if ! command -v pct >/dev/null 2>&1; then
    echo "This script requires a Proxmox host with pct available."
    exit 1
fi

if pct status "$CT_ID" >/dev/null 2>&1; then
    echo "Container $CT_ID already exists."
    exit 0
fi

pct create "$CT_ID" "$TEMPLATE" --hostname nextcloud --memory "$MEMORY" --rootfs "$STORAGE:${DISK}" --features nesting=1 --net0 name=eth0,bridge=vmbr0,ip=192.168.100.102/24,gw=192.168.100.1 --ostype ubuntu --unprivileged 1
pct start "$CT_ID"

sleep 15
pct exec "$CT_ID" -- bash -lc "apt-get update -y && apt-get install -y nginx mariadb-server php8.2 php8.2-cli php8.2-gd php8.2-mysql php8.2-curl php8.2-xml php8.2-intl php8.2-mbstring php8.2-zip php8.2-apcu php8.2-imagick redis-server libapache2-mod-php"

cat <<EOF
Nextcloud container created successfully.
Internal IP: 192.168.100.102
Web UI: https://cloud.yourdomain.com
EOF
