#!/bin/bash
set -euo pipefail

if ! command -v fail2ban-client >/dev/null 2>&1; then
    echo "fail2ban is not installed."
    exit 1
fi

fail2ban-client start >/dev/null 2>&1 || true
fail2ban-client reload >/dev/null 2>&1 || true

echo "Fail2ban configuration reloaded."
