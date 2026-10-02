# BDA Troubleshooting Guide

## Common issues

### Proxmox is not detected

Check:

```bash
cat /etc/proxmox-release
```

If the file is missing, Proxmox is not installed properly.

### LXC container creation fails

Check that the template exists:

```bash
pveam list local
```

If not present, run:

```bash
pveam update
pveam download local ubuntu-22.04-standard_22.04-1_amd64.tar.zst
```

### n8n fails to start

Check the service:

```bash
systemctl status n8n
journalctl -u n8n -n 50
```

### Nextcloud refuses to load

Verify the container is running and the port is reachable:

```bash
pct status 102
curl -I http://192.168.100.102
```

### Mail-in-a-Box not working

Ensure:

- port 25 is enabled in the network path
- DNS records are configured
- the container is privileged and has nested features enabled

### SSL warnings in browser

This is expected with self-signed certificates. For a valid certificate, use:

```bash
certbot --nginx -d yourdomain.com -d mail.yourdomain.com -d cloud.yourdomain.com -d automate.yourdomain.com -d adguard.yourdomain.com -d crm.yourdomain.com -d ai.yourdomain.com
```

## Logs to inspect

- `/var/log/bda-health.log`
- `/var/log/bda-backup.log`
- `/var/log/bda-update.log`
- `/var/log/bda-ssl-renew.log`
- `/var/log/nginx/error.log`

## Useful commands

```bash
# list containers
pct list

# inspect a container
pct exec 102 -- bash

# health check
/root/bda-rpu/scripts/maintenance/health-check.sh

# backup
/root/bda-rpu/scripts/maintenance/backup-all.sh
```
