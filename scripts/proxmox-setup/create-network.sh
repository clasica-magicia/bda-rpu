#!/bin/bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[INFO]${NC}  $1"; }
print_warning() { echo -e "${YELLOW}[WARN]${NC}  $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

if [[ $(id -u) -ne 0 ]]; then
    print_error "Run as root."
    exit 1
fi

PRIMARY_IFACE="$(ip route | awk '/default/ {print $5; exit}')"
if [[ -z "$PRIMARY_IFACE" ]]; then
    print_error "No default network interface detected."
    exit 1
fi

print_status "Detected primary interface: $PRIMARY_IFACE"

# Configure a bridge if it does not already exist.
if ! ip link show vmbr0 >/dev/null 2>&1; then
    ip link add vmbr0 type bridge
fi

# Attach the host interface to the bridge if it is not already bridged.
if ! ip link show | grep -q "master vmbr0"; then
    ip link set "$PRIMARY_IFACE" master vmbr0 || true
fi

ip link set vmbr0 up

cat > /etc/network/interfaces <<EOF
source /etc/network/interfaces.d/*

auto lo
iface lo inet loopback

auto vmbr0
iface vmbr0 inet dhcp
    bridge-ports $PRIMARY_IFACE
    bridge-stp off
    bridge-fd 0
EOF

print_status "Network bridge configured. Reboot or reload networking to apply changes."
