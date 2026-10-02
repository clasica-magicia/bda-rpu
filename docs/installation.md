# Installation Guide

## 1. Hardware and OS prerequisites

Before running the BDA provisioning scripts, check that you have:

- A Proxmox VE host or a Debian/Ubuntu system compatible with the installer
- At least 16 GB RAM and 500 GB SSD/HDD storage
- A valid domain name (recommended for mail and SSL)
- Network access with a static or DHCP-managed IP range

## 2. Install Proxmox VE

1. Download the Proxmox ISO from the official project website.
2. Create a bootable USB and install Proxmox on the host machine.
3. Set a strong root password.
4. Ensure the network bridge `vmbr0` is available and connected to the correct NIC.

## 3. Clone this repository

```bash
git clone https://github.com/clasica-magicia/bda-rpu.git /root/bda-rpu
cd /root/bda-rpu
chmod +x install.sh
```

## 4. Run the installer

```bash
./install.sh
```

The installer will prompt for:

- Domain name
- Public IP address
- Admin email
- Whether to deploy AI services

## 5. Post-install validation

After deployment, validate each service:

- https://mail.example.com
- https://cloud.example.com
- http://192.168.100.103:5678
- http://192.168.100.104:3000
- http://192.168.100.106
- http://192.168.100.107:8080

## 6. DNS and certificates

If you are using a public domain, configure these records:

- A / AAAA records for the host
- MX record for mail traffic
- SPF, DKIM, DMARC for mail delivery
- reverse proxy and TLS entries for the web applications

## 7. Maintenance

The installer creates cron jobs for:

- health checks
- backups
- updates
- SSL renewal

Review logs in `/var/log` for any failures.
