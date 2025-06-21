#!/usr/bin/env bash
set -euo pipefail

. /scripts/utils.sh

log "Clearing nginx proxy cache …"

rm -rf /dev/shm/nginx_cache/* || true
# reload nginx config so that any stale cache metadata is dropped
nginx -s reload || true
