#!/bin/bash
set -euo pipefail

DOMAIN="${1:-local}"
if [[ -z "$DOMAIN" || "$DOMAIN" == "local" ]]; then
    echo "Skipping certificate generation for local-only deployment."
    exit 0
fi

if command -v certbot >/dev/null 2>&1; then
    certbot certonly --standalone --agree-tos --email admin@"$DOMAIN" -d "$DOMAIN" -d "mail.$DOMAIN" -d "cloud.$DOMAIN" -d "automate.$DOMAIN" -d "adguard.$DOMAIN" -d "crm.$DOMAIN" -d "ai.$DOMAIN" >/dev/null 2>&1 || true
fi

echo "SSL generation complete or skipped."
