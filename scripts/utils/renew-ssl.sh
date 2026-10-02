#!/bin/bash
set -euo pipefail

if command -v certbot >/dev/null 2>&1; then
    certbot renew --quiet || true
fi

echo "SSL renewal check complete."
