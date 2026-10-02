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

print_status "Hardening SSH"
if [[ ! -f /root/.ssh/id_ed25519 ]]; then
    mkdir -p /root/.ssh
    ssh-keygen -t ed25519 -C "admin@bda" -f /root/.ssh/id_ed25519 -N ""
    print_status "SSH key generated at /root/.ssh/id_ed25519"
else
    print_warning "SSH key already exists; skipping generation."
fi

SSHD_CONFIG="/etc/ssh/sshd_config"
cp "$SSHD_CONFIG" "$SSHD_CONFIG.bak" 2>/dev/null || true
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' "$SSHD_CONFIG"
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' "$SSHD_CONFIG"
sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' "$SSHD_CONFIG"

systemctl restart sshd || systemctl restart ssh
print_status "SSH hardening applied"

print_status "Enabling firewall rules"
if command -v pve-firewall >/dev/null 2>&1; then
    pvesh set /cluster/firewall/options --enable 1 || true
    cat > /etc/pve/firewall/cluster.fw <<'FW'
[OPTIONS]
enable: 1
policy_out: accept

[RULES]
IN ACCEPT -p tcp -dport 22
IN ACCEPT -p tcp -dport 8006
IN ACCEPT -p tcp -dport 80
IN ACCEPT -p tcp -dport 443
IN DROP
FW
fi

print_status "Installing fail2ban"
apt-get install -y fail2ban >/dev/null
cat > /etc/fail2ban/jail.local <<'F2B'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3

[proxmox]
enabled = true
port = 8006
filter = proxmox
logpath = /var/log/daemon.log
maxretry = 3
F2B

cat > /etc/fail2ban/filter.d/proxmox.conf <<'F2BF'
[Definition]
failregex = pvedaemon\[.*\]: authentication failure; rhost=<HOST> user=.* msg=.*
ignoreregex =
F2BF

systemctl enable fail2ban || true
systemctl restart fail2ban || true

print_status "Configuring unattended upgrades"
apt-get install -y unattended-upgrades apt-listchanges >/dev/null
cat > /etc/apt/apt.conf.d/50unattended-upgrades <<'UU'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}";
    "${distro_id}:${distro_codename}-security";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infrastructure-security";
};
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-New-Unused-Dependencies "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
UU

cat > /etc/apt/apt.conf.d/20auto-upgrades <<'AU'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
AU

print_status "Installing rkhunter and logwatch"
apt-get install -y rkhunter logwatch >/dev/null
rkhunter --update >/dev/null 2>&1 || true
rkhunter --propupd >/dev/null 2>&1 || true
echo "0 5 * * * root /usr/bin/rkhunter --cronjob --report-warnings-only" > /etc/cron.d/rkhunter
echo "0 6 * * * root /usr/sbin/logwatch" > /etc/cron.d/00logwatch

print_status "Applying sysctl hardening"
cat > /etc/sysctl.d/99-bda-hardening.conf <<'SYSCTL'
net.ipv4.ip_forward = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.tcp_syncookies = 1
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2
SYSCTL
sysctl --system >/dev/null 2>&1 || true

print_status "Security hardening complete"
print_warning "Add your SSH public key to /root/.ssh/authorized_keys before closing the session."
