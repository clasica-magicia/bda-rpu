# BDA Installation Guide

## Prerequisites

- Proxmox VE installed and running
- Root SSH access to the Proxmox host
- Internet connectivity for package downloads
- Optional: a public domain and open ports for email/HTTPS

## Step-by-step

### 1. Install Proxmox VE

1. Download Proxmox VE from the official site.
2. Flash it to a USB drive.
3. Boot the target mini PC from that USB and install Proxmox.
4. Log in to the web UI at https://YOUR_IP:8006.

### 2. Prepare the host

SSH into the Proxmox host as root:

```bash
ssh root@YOUR_PROXMOX_IP
```

Then run:

```bash
cd /root
git clone https://github.com/clasica-magicia/bda-rpu.git
cd /root/bda-rpu
chmod +x install.sh
./install.sh
```

### 3. Follow the prompts

The installer asks for:

- domain name
- public IP
- admin email
- whether to deploy the AI stack

### 4. Post-installation steps

- Change all default passwords.
- Set up DNS A-records and MX records.
- Ensure port 25 is open for Mail-in-a-Box.
- Replace self-signed certificates with valid Let's Encrypt certificates when possible.
- Test backups and health status.

## Quick reference

| Service | Internal URL |
| --- | --- |
| Mail Server | https://192.168.100.101 |
| Nextcloud | http://192.168.100.102 |
| n8n | http://192.168.100.103:5678 |
| AdGuard | http://192.168.100.104:3000 |
| SuiteCRM | http://192.168.100.106 |
| Open WebUI | http://192.168.100.107:8080 |

## Notes

This installation should be treated as a production baseline and reviewed before exposure to the public internet.
