#!/bin/bash
set -euo pipefail

TARGET="${1:-https://localhost}"

curl -fsS "$TARGET" >/dev/null 2>&1 || {
    echo "Health check failed for $TARGET" >&2
    exit 1
}

echo "OK $TARGET"
