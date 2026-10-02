#!/bin/bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[INFO]${NC}  $1"; }
print_warning() { echo -e "${YELLOW}[WARN]${NC}  $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_step() { echo -e "\n${CYAN}================================================${NC}\n${CYAN}$1${NC}\n${CYAN}================================================${NC}\n"; }

require_root() {
    if [[ $(id -u) -ne 0 ]]; then
        print_error "This installer must be run as root."
        exit 1
    fi
}

ensure_repo() {
    local repo_dir="/root/bda-rpu"
    if [[ -d "$repo_dir/.git" ]]; then
        print_status "Repository already present at $repo_dir"
        cd "$repo_dir"
        git pull --ff-only || true
        return
    fi

    print_step "Cloning repository"
    git clone https://github.com/clasica-magicia/bda-rpu.git "$repo_dir"
    cd "$repo_dir"
}

install_base_packages() {
    print_step "Installing base packages"
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y --no-install-recommends \
        ca-certificates curl wget git jq unzip gnupg \
        certbot python3-certbot-nginx nginx rsync cron \
        fail2ban unattended-upgrades apt-listchanges software-properties-common
}

configure_defaults() {
    DOMAIN="${DOMAIN:-local}"
    PUBLIC_IP="${PUBLIC_IP:-$(hostname -I 2>/dev/null | awk '{print $1}' || echo 127.0.0.1)}"
    ADMIN_EMAIL="${ADMIN_EMAIL:-admin@${DOMAIN}}"

    print_status "Domain: $DOMAIN"
    print_status "Public IP: $PUBLIC_IP"
    print_status "Admin email: $ADMIN_EMAIL"
}

run_proxmox_setup() {
    if [[ -f /etc/proxmox-release ]]; then
        print_step "Running Proxmox host hardening"
        chmod +x scripts/proxmox-setup/create-network.sh
        chmod +x scripts/proxmox-setup/harden-security.sh
        scripts/proxmox-setup/create-network.sh || true
        scripts/proxmox-setup/harden-security.sh || true
    else
        print_warning "This host is not running Proxmox; skipping Proxmox-specific setup."
    fi
}

deploy_services() {
    print_step "Deploying services"
    for script in \
        scripts/services/deploy-nextcloud.sh \
        scripts/services/deploy-n8n.sh \
        scripts/services/deploy-adguard.sh \
        scripts/services/deploy-restic.sh \
        scripts/services/deploy-crm.sh; do
        chmod +x "$script"
        if [[ -f /etc/proxmox-release ]]; then
            "$script" || true
        else
            print_warning "Skipping $script because Proxmox is not detected."
        fi
    done

    if [[ "$DOMAIN" != "local" ]]; then
        chmod +x scripts/services/deploy-mailbox.sh
        if [[ -f /etc/proxmox-release ]]; then
            scripts/services/deploy-mailbox.sh "$DOMAIN" || true
        fi
    fi

    if [[ "${DEPLOY_AI:-y}" =~ ^[Yy]$ ]]; then
        chmod +x scripts/services/deploy-ollama.sh
        if [[ -f /etc/proxmox-release ]]; then
            scripts/services/deploy-ollama.sh || true
        fi
    fi
}

configure_nginx() {
    print_step "Configuring Nginx reverse proxy"
    mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
    for file in configs/nginx/*.conf; do
        [[ -e "$file" ]] || continue
        cp "$file" /etc/nginx/sites-available/
        target="/etc/nginx/sites-enabled/$(basename "$file")"
        if [[ ! -L "$target" ]]; then
            ln -sf "/etc/nginx/sites-available/$(basename "$file")" "$target"
        fi
    done

    if [[ -f /etc/nginx/sites-enabled/default ]]; then
        rm -f /etc/nginx/sites-enabled/default
    fi

    if [[ -f /etc/nginx/conf.d/default.conf ]]; then
        rm -f /etc/nginx/conf.d/default.conf
    fi

    if nginx -t >/tmp/bda-nginx-test.log 2>&1; then
        systemctl reload nginx || systemctl restart nginx
    else
        print_error "Nginx configuration test failed. Review /tmp/bda-nginx-test.log"
    fi
}

configure_ssl() {
    print_step "Generating or refreshing SSL assets"
    chmod +x scripts/utils/generate-ssl.sh
    scripts/utils/generate-ssl.sh "$DOMAIN" || true
}

setup_maintenance() {
    print_step "Setting up maintenance jobs"
    chmod +x scripts/maintenance/health-check.sh
    chmod +x scripts/maintenance/backup-all.sh
    chmod +x scripts/maintenance/update-all.sh
    chmod +x scripts/utils/renew-ssl.sh
    chmod +x scripts/utils/setup-fail2ban.sh
    scripts/utils/setup-fail2ban.sh || true

    local cronfile="/tmp/bda-crontab"
    crontab -l > "$cronfile" 2>/dev/null || true
    sed -i '/bda-rpu/d' "$cronfile" 2>/dev/null || true

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
}

deploy_dashboard() {
    print_step "Deploying dashboard"
    mkdir -p /var/www/html
    cp -r web/* /var/www/html/
    chown -R www-data:www-data /var/www/html || true
    chmod -R 755 /var/www/html
    sed -i "s/yourdomain\.com/${DOMAIN}/g" /var/www/html/index.html || true
    sed -i "s/PUBLIC_IP_PLACEHOLDER/${PUBLIC_IP}/g" /var/www/html/index.html || true
}

show_completion() {
    echo
    echo -e "${GREEN}================================================${NC}"
    echo -e "${GREEN}BDA installation complete${NC}"
    echo -e "${GREEN}================================================${NC}"
    echo
    echo "Services:"
    echo "  Dashboard: https://${DOMAIN}"
    echo "  Mail:      https://mail.${DOMAIN}"
    echo "  Nextcloud: https://cloud.${DOMAIN}"
    echo "  n8n:      http://${PUBLIC_IP}:5678"
    echo "  AdGuard:  http://${PUBLIC_IP}:3000"
    echo "  CRM:      http://${PUBLIC_IP}:80"
    echo "  AI:       http://${PUBLIC_IP}:8080"
    echo
    echo "Important next steps:"
    echo "  1. Change default passwords"
    echo "  2. Configure your domain DNS records"
    echo "  3. Review health-check and backup output"
    echo "  4. Secure your Proxmox host and SSH access"
}

main() {
    require_root
    configure_defaults
    ensure_repo
    install_base_packages
    run_proxmox_setup
    deploy_services
    configure_ssl
    configure_nginx
    setup_maintenance
    deploy_dashboard
    show_completion
}

main "$@"
