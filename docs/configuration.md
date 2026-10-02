# Configuration Guide

## Network layout

The default BDA network uses a bridge interface named `vmbr0` and a private range like `192.168.100.0/24`.

Example:

- Host: `192.168.100.1`
- CT 101: `192.168.100.101`
- CT 102: `192.168.100.102`
- CT 103: `192.168.100.103`
- CT 104: `192.168.100.104`
- CT 105: `192.168.100.105`
- CT 106: `192.168.100.106`
- CT 107: `192.168.100.107`

## Nginx configuration

The repository ships prebuilt Nginx virtual host files under `configs/nginx/`.
Each file contains placeholders handled by the installer and should be adjusted for a real domain.

Example values to replace:

- `yourdomain.com`
- `example.com`
- internal service ports

## Security settings

Recommended defaults:

- Disable password SSH authentication
- Keep key-based SSH access only
- Limit Proxmox web UI access behind trusted IP ranges or VPN
- Enable fail2ban and automatic security patches
- Keep backups encrypted and offsite if possible

## Container and service notes

- Mail server should be treated as the authoritative host for SMTP and MX traffic.
- Nextcloud and SuiteCRM should be exposed only through proper TLS and trusted DNS.
- AdGuard Home should be placed on the network as the DNS resolver for local devices.
- Ollama should remain local-only unless you explicitly expose it externally.
