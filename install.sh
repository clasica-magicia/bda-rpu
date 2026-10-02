#!/usr/bin/env bash
set -Eeuo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_status(){ echo -e "${GREEN}[INFO]${NC}  $1"; }
print_warning(){ echo -e "${YELLOW}[WARN]${NC}  $1"; }
print_error(){ echo -e "${RED}[ERROR]${NC} $1"; }
print_step(){ echo -e "\n${CYAN}========================================${NC}\n${CYAN}$1${NC}\n${CYAN}========================================${NC}\n"; }

require_root(){
  if [[ $(id -u) -ne 0 ]]; then
    print_error "This script must be run as root on the Proxmox host."
    exit 1
  fi
}

check_proxmox(){
  if [[ ! -f /etc/proxmox-release ]]; then
    print_error "Proxmox VE is not installed. Please install Proxmox first."
    exit 1
  fi
  print_status "Proxmox VE detected: $(cat /etc/proxmox-release)"
}

prompt_for_config() {
  print_step "Gathering configuration"

  read -rp "Your domain name (e.g. yourbusiness.com, leave blank for local-only): " DOMAIN
  DOMAIN="${DOMAIN:-local}"

  read -rp "Public IP of this server (leave blank to auto-detect): " PUBLIC_IP
  PUBLIC_IP="${PUBLIC_IP:-$(hostname -I | awk '{print $1}') }"
  PUBLIC_IP="${PUBLIC_IP%%[[:space:]]*}"

  read -rp "Admin email for notifications [admin@${DOMAIN}]: " ADMIN_EMAIL
  ADMIN_EMAIL="${ADMIN_EMAIL:-admin@${DOMAIN}}"

  printf '\n'
  print_status "Domain:    ${DOMAIN}"
  print_status "Public IP: ${PUBLIC_IP}"
  print_status "Email:     ${ADMIN_EMAIL}"
}

update_system(){
  print_step "Updating the Proxmox host"
  apt-get update -y
  apt-get dist-upgrade -y
  apt-get install -y git curl wget vim htop unzip software-properties-common ca-certificates
}

install_packages(){
  print_step "Installing common packages"
  apt-get install -y nginx certbot python3-certbot-nginx rsync jq
}

clone_repo(){
  print_step "Setting up repository"
  local repo_path="/root/bda-rpu"
  if [[ -d "$repo_path" ]]; then
    print_warning "Repository already exists at $repo_path"
    git -C "$repo_path" pull --ff-only || true
  else
    git clone https://github.com/clasica-magicia/bda-rpu.git "$repo_path"
  fi
  cd "$repo_path"
}

setup_network(){
  print_step "Configuring networking"
  chmod +x scripts/proxmox-setup/create-network.sh
  scripts/proxmox-setup/create-network.sh || true
}

harden_security(){
  print_step "Hardening Proxmox host"
  chmod +x scripts/proxmox-setup/harden-security.sh
  scripts/proxmox-setup/harden-security.sh || true
}

deploy_services(){
  print_step "Deploying services"
  local svc_dir="/root/bda-rpu/scripts/services"

  print_status "Downloading Ubuntu 22.04 LXC template if needed"
  pveam update || true
  if ! pveam list local 2>/dev/null | grep -q 'ubuntu-22.04-standard'; then
    pveam download local ubuntu-22.04-standard_22.04-1_amd64.tar.zst || true
  fi

  if [[ "$DOMAIN" != "local" ]]; then
    print_status "Deploying Mail Server (CT 101)"
    chmod +x "$svc_dir/deploy-mailbox.sh"
    "$svc_dir/deploy-mailbox.sh" "$DOMAIN" || true
  else
    print_warning "Skipping Mail-in-a-Box because no domain was configured."
  fi

  print_status "Deploying Nextcloud (CT 102)"
  chmod +x "$svc_dir/deploy-nextcloud.sh"
  "$svc_dir/deploy-nextcloud.sh" || true

  print_status "Deploying n8n (CT 103)"
  chmod +x "$svc_dir/deploy-n8n.sh"
  "$svc_dir/deploy-n8n.sh" || true

  print_status "Deploying AdGuard Home (CT 104)"
  chmod +x "$svc_dir/deploy-adguard.sh"
  "$svc_dir/deploy-adguard.sh" || true

  print_status "Deploying Restic backup host (CT 105)"
  chmod +x "$svc_dir/deploy-restic.sh"
  "$svc_dir/deploy-restic.sh" || true

  print_status "Deploying SuiteCRM (CT 106)"
  chmod +x "$svc_dir/deploy-crm.sh"
  "$svc_dir/deploy-crm.sh" || true

  read -rp "Deploy AI services (Ollama + Open WebUI)? [y/N]: " DEPLOY_AI
  if [[ "$DEPLOY_AI" =~ ^[Yy]$ ]]; then
    print_status "Deploying Ollama + Open WebUI (CT 107)"
    chmod +x "$svc_dir/deploy-ollama.sh"
    "$svc_dir/deploy-ollama.sh" || true
  else
    print_warning "Skipping AI services."
  fi
}

generate_ssl(){
  print_step "Generating SSL certificates"
  chmod +x /root/bda-rpu/scripts/utils/generate-ssl.sh
  /root/bda-rpu/scripts/utils/generate-ssl.sh "$DOMAIN" || true
}

setup_reverse_proxy(){
  print_step "Configuring Nginx reverse proxy"
  for f in /root/bda-rpu/configs/nginx/*.conf; do
    [[ -f "$f" ]] || continue
    sed -i "s/yourdomain\.com/${DOMAIN}/g" "$f"
  done

  mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
  cp /root/bda-rpu/configs/nginx/*.conf /etc/nginx/sites-available/ 2>/dev/null || true

  for f in /root/bda-rpu/configs/nginx/*.conf; do
    [[ -f "$f" ]] || continue
    base="$(basename "$f")"
    if [[ ! -L "/etc/nginx/sites-enabled/$base" ]]; then
      ln -s "/etc/nginx/sites-available/$base" "/etc/nginx/sites-enabled/$base" || true
    fi
  done

  rm -f /etc/nginx/sites-enabled/default
  if nginx -t 2>/dev/null; then
    systemctl reload nginx || true
  else
    print_warning "Nginx configuration test failed. Please review with nginx -t."
  fi
}

setup_fail2ban(){
  print_step "Configuring Fail2Ban"
  chmod +x /root/bda-rpu/scripts/utils/setup-fail2ban.sh
  /root/bda-rpu/scripts/utils/setup-fail2ban.sh || true
}

setup_maintenance(){
  print_step "Installing maintenance cron jobs"
  chmod +x /root/bda-rpu/scripts/maintenance/health-check.sh
  chmod +x /root/bda-rpu/scripts/maintenance/backup-all.sh
  chmod +x /root/bda-rpu/scripts/maintenance/update-all.sh
  chmod +x /root/bda-rpu/scripts/utils/renew-ssl.sh

  local cronfile="/tmp/bda-crontab"
  crontab -l > "$cronfile" 2>/dev/null || true
  sed -i '/bda-rpu/d' "$cronfile" || true

  cat >> "$cronfile" <<CRON
# BDA health check - every hour
0 * * * * /root/bda-rpu/scripts/maintenance/health-check.sh >> /var/log/bda-health.log 2>&1
# BDA backup - daily at 02:00
0 2 * * * /root/bda-rpu/scripts/maintenance/backup-all.sh >> /var/log/bda-backup.log 2>&1
# BDA update - weekly Sunday 03:00
0 3 * * 0 /root/bda-rpu/scripts/maintenance/update-all.sh >> /var/log/bda-update.log 2>&1
# BDA SSL renewal - daily at 03:30
30 3 * * * /root/bda-rpu/scripts/utils/renew-ssl.sh >> /var/log/bda-ssl-renew.log 2>&1
CRON

  crontab "$cronfile"
  rm -f "$cronfile"
  print_status "Cron jobs installed."
}

setup_dashboard(){
  print_step "Deploying dashboard"
  mkdir -p /var/www/html
  sed -i "s/yourdomain\.com/${DOMAIN}/g" /root/bda-rpu/web/index.html
  sed -i "s/PUBLIC_IP_PLACEHOLDER/${PUBLIC_IP}/g" /root/bda-rpu/web/index.html
  cp -r /root/bda-rpu/web/* /var/www/html/
  chown -R www-data:www-data /var/www/html/
  chmod -R 755 /var/www/html/
  print_status "Dashboard deployed to /var/www/html/"
}

display_completion(){
  echo
  echo -e "${GREEN}============================================================${NC}"
  echo -e "${GREEN}BDA installation complete${NC}"
  echo -e "${GREEN}============================================================${NC}"
  echo
  echo "Next steps:"
  echo "  1. Change default passwords"
  echo "  2. Configure DNS records for your domain"
  echo "  3. Review services and logs"
  echo "  4. Run health checks and backups"
  echo
  echo "Useful links:"
  echo "  Dashboard: https://${DOMAIN}"
  echo "  Proxmox:   https://${PUBLIC_IP}:8006"
  echo "  Repo:      https://github.com/clasica-magicia/bda-rpu"
}

main(){
  require_root
  check_proxmox
  prompt_for_config
  update_system
  install_packages
  clone_repo
  setup_network
  harden_security
  deploy_services
  generate_ssl
  setup_reverse_proxy
  setup_fail2ban
  setup_maintenance
  setup_dashboard
  display_completion
}

main "$@"
