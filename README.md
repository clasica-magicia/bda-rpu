# Business Digital Assistant (BDA)

A complete self-hosted digital ecosystem for small businesses, replacing expensive SaaS subscriptions with a single local appliance or Proxmox-based deployment.

## Overview

This repository packages the Business Digital Assistant stack so you can deploy a fully self-hosted environment on a mini PC or Proxmox host. The stack includes:

- Mail server / secure inbox
- Nextcloud for file sync and collaboration
- n8n for workflow automation
- SuiteCRM for customer management
- AdGuard Home for network-wide ad blocking
- Restic for encrypted backup automation
- Ollama + Open WebUI for local AI workloads
- Proxmox/host hardening and security tooling
- Nginx reverse proxy and dashboard UI

## Architecture

The default installation targets a Proxmox VE host with multiple LXC containers and shared network bridging. The canonical map is:

- CT 101: Mail Server, 192.168.100.101, 443
- CT 102: Nextcloud, 192.168.100.102, 443
- CT 103: n8n, 192.168.100.103, 5678
- CT 104: AdGuard Home, 192.168.100.104, 3000/80
- CT 105: Restic Backup, 192.168.100.105
- CT 106: CRM (SuiteCRM), 192.168.100.106, 80/443
- CT 107: Ollama + Open WebUI, 192.168.100.107, 11434 / 8080

## Features

- Secure email and local webmail
- Dropbox/Google Drive replacement with Nextcloud
- Zapier replacement via n8n
- Customer data management via SuiteCRM
- DNS filtering and ad blocking
- Encrypted backups with rotation
- Local AI processing with privacy-first data handling
- Monitoring, maintenance, SSL renewal, and health checks

## Quick start

### Prerequisites

- Proxmox VE host (or Ubuntu/Debian host compatible with the scripts)
- 16 GB RAM minimum, 500 GB+ storage recommended
- Optional domain name for public HTTPS access
- Network access for the host and containers

### Install

```bash
chmod +x install.sh
./install.sh
```

Follow the interactive prompts for domain, public IP, and admin email.

### Alternative local deployment

```bash
docker compose up -d
```

## Repository layout

```text
bda-rpu/
├── README.md
├── install.sh
├── docker-compose.yml
├── docs/
│   ├── installation.md
│   ├── configuration.md
│   └── troubleshooting.md
├── scripts/
│   ├── proxmox-setup/
│   │   ├── create-network.sh
│   │   └── harden-security.sh
│   ├── services/
│   │   ├── deploy-mailbox.sh
│   │   ├── deploy-nextcloud.sh
│   │   ├── deploy-n8n.sh
│   │   ├── deploy-adguard.sh
│   │   ├── deploy-restic.sh
│   │   ├── deploy-ollama.sh
│   │   └── deploy-crm.sh
│   ├── maintenance/
│   │   ├── health-check.sh
│   │   ├── backup-all.sh
│   │   └── update-all.sh
│   └── utils/
│       ├── generate-ssl.sh
│       ├── setup-fail2ban.sh
│       └── renew-ssl.sh
├── configs/
│   └── nginx/
│       ├── bda.conf
│       ├── mail.conf
│       ├── nextcloud.conf
│       ├── n8n.conf
│       ├── adguard.conf
│       ├── crm.conf
│       └── ollama.conf
├── web/
│   ├── index.html
│   ├── css/
│   │   └── style.css
│   └── js/
│       └── app.js
├── .gitignore
├── LICENSE
└── .github/ (optional automation, if enabled later)
```

## Documentation

- [Installation Guide](docs/installation.md)
- [Configuration Guide](docs/configuration.md)
- [Troubleshooting Guide](docs/troubleshooting.md)

## Security notes

- Change default passwords immediately after deployment.
- Keep SSH keys in place and remove password authentication.
- Rotate backup credentials and store them securely.
- Use proper DNS entries for email and HTTPS.

## License

This project is distributed under the MIT License.

## Support

For questions or issues, open a GitHub issue in this repository.
