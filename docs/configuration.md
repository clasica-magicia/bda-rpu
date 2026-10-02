# BDA Configuration Guide

## Network layout

The Proxmox host uses a Linux bridge for internal LXC networking:

- Physical interface: detected automatically
- Bridge: vmbr0
- Internal network: 192.168.100.0/24

## Container map

| CT ID | Service | IP |
| --- | --- | --- |
| 101 | Mail Server | 192.168.100.101 |
| 102 | Nextcloud | 192.168.100.102 |
| 103 | n8n | 192.168.100.103 |
| 104 | AdGuard Home | 192.168.100.104 |
| 105 | Restic Backup | 192.168.100.105 |
| 106 | SuiteCRM | 192.168.100.106 |
| 107 | Ollama/Open WebUI | 192.168.100.107 |

## DNS recommendations

If you have a domain name, point these records to the public IP:

- yourdomain.com
- mail.yourdomain.com
- cloud.yourdomain.com
- automate.yourdomain.com
- adguard.yourdomain.com
- crm.yourdomain.com
- ai.yourdomain.com

For Mail-in-a-Box, also configure:

- MX
- SPF
- DKIM
- DMARC

## Reverse proxy

The repository includes Nginx vhost definitions under `configs/nginx/`.

Each config file is intended to be copied into `/etc/nginx/sites-available` and symlinked in `/etc/nginx/sites-enabled`.

## TLS

- Default: self-signed certificate at `/etc/ssl/certs/bda.crt`
- Production: use Let's Encrypt with a real domain

## Maintenance tasks

The cron jobs installed by the repo do the following:

- hourly health checks
- nightly backup
- weekly update pass
- daily SSL renewal check

## Security hardening

The default hardening script:

- disables password SSH login
- generates an SSH keypair
- enables the Proxmox firewall
- configures Fail2Ban
- enables unattended upgrades
- installs rkhunter and logwatch
