# Troubleshooting Guide

## SSH lockout

If SSH access stops working:

1. Log into the host through the local console or rescue shell.
2. Verify the SSH daemon config.
3. Confirm `sshd_config` still permits key-based login.
4. Restore the backup file if needed:

```bash
cp /etc/ssh/sshd_config.bak /etc/ssh/sshd_config
systemctl restart ssh
```

## Nginx test fails

Run:

```bash
nginx -t
```

Then review any syntax errors in the relevant config under `/etc/nginx/sites-available/`.

## Proxmox container creation fails

Common causes:

- missing LXC template
- invalid CT ID collision
- insufficient root disk or memory allocation
- incorrect storage identifier

Check:

```bash
pveam update
pveam list local
pct list
```

## Backups fail

Check logs:

```bash
cat /var/log/bda-backup.log
```

Verify:

- Restic repository is initialized
- repository password is correct
- storage path is mounted and writable

## Dashboard not loading

Check:

```bash
ls -l /var/www/html
systemctl status nginx
```

Ensure the HTML was copied and permissions are correct.
