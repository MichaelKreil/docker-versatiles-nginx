#!/usr/bin/env bash
set -euo pipefail

############### helper ################
log() { echo "[$(date +%FT%T%z)] $*"; }
require() { [ -n "${!1:-}" ] || { echo "Env \$${1} is required"; exit 1; }; }
calc_cache() {
  local mem_kb
  mem_kb=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
  # 20 % to keys, 60 % to data
  KEY_AUTO=$((mem_kb / 5))k
  MAX_AUTO=$((mem_kb * 3 / 5))k
}

############### pre‑flight ############
require DOMAIN
require EMAIL
VERSATILES_ARGS=""

# fix ownership of the unified volume
chown -R vs:vs /data || true

# calculate cache sizes if not provided
calc_cache
CACHE_KEYS=${CACHE_SIZE_KEYS:-$KEY_AUTO}
CACHE_MAX=${CACHE_SIZE_MAX:-$MAX_AUTO}

# frontend download (optional)
mkdir -p /data/frontend
if [ "${FRONTEND_VARIANT}" != "none" ]; then
  case "${FRONTEND_VARIANT}" in
    "dev") FRONTEND_VARIANT="frontend-dev" ;;
    "min") FRONTEND_VARIANT="frontend-min" ;;
    *) FRONTEND_VARIANT="frontend";;
  esac

  FILENAME="${FRONTEND_VARIANT}.br.tar.gz"
  PATH="/data/frontend/${FILENAME}"
  if [ ! -f "${PATH}" ]; then
    log "Downloading ${FRONTEND_VARIANT} …"
    curl -L "https://github.com/versatiles-org/versatiles-frontend/releases/latest/download/${FILENAME}" -o "${PATH}"
  fi
  VERSATILES_ARGS+=" --static ${PATH}"
fi

# user defined static files
mkdir -p /data/static
VERSATILES_ARGS+=" --static /data/static"

# ensure local tile sources exist or fetch them
mkdir -p /data/tiles
IFS=',' read -ra TS <<< "${TILE_SOURCES}"
for SRC in "${TS[@]}"; do
  [ -z "$SRC" ] && continue
  if [ ! -f "/data/tiles/$SRC" ]; then
    log "Fetching missing tile source $SRC …"
    curl -L "https://download.versatiles.org/$SRC" -o "/data/tiles/$SRC"
  fi
  VERSATILES_ARGS+=" /data/tiles/$SRC"
done

############### nginx stub ############
cat >/etc/nginx/nginx.conf <<EOF
worker_processes auto;
error_log /dev/stdout info;
pid /run/nginx.pid;

events { worker_connections 1024; }

http {
  include       /etc/nginx/mime.types;
  default_type  application/octet-stream;
  access_log    /dev/stdout;
  sendfile      on;
  server_tokens off;

  server {
    listen 80 default_server;
    server_name ${DOMAIN};

    location / { return 404; }
  }
}
EOF

log "Starting nginx stub …"
nginx &
NGINX_STUB_PID=$!

############### ACME ##################
log "Requesting/renewing certificate …"
certbot --nginx -n --agree-tos -m "$EMAIL" -d "$DOMAIN"

############### nginx full TLS config ############
cat >/etc/nginx/nginx.conf <<EOF
worker_processes auto;
error_log /dev/stdout info;
pid /run/nginx.pid;

events { worker_connections 1024; }

http {
  include       /etc/nginx/mime.types;
  default_type  application/octet-stream;
  access_log    /dev/stdout;
  sendfile      on;
  server_tokens off;

  proxy_cache_path /dev/shm/nginx_cache levels=1:2 keys_zone=tiles:${CACHE_KEYS} max_size=${CACHE_MAX} inactive=24h;

  # status endpoint on 127.0.0.1:8090
  server {
    listen 127.0.0.1:8090;
    location /_nginx_status { stub_status; allow 127.0.0.1; deny all; }
  }

  # redirect HTTP → HTTPS
  server {
    listen 80 default_server;
    server_name ${DOMAIN};
    return 301 https://$host$request_uri;
  }

  # HTTPS server
  server {
    listen 443 ssl http2;
    server_name ${DOMAIN};

    ssl_certificate     /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;

    # frontend (if any)
    location / {
      root /data/frontend;
      try_files $uri /index.html =404;
    }

    # tile backend
    location /tiles/ {
      proxy_pass http://127.0.0.1:8080/;
      proxy_cache tiles;
      proxy_cache_valid 200 60m;
      add_header X-Cache $upstream_cache_status;
    }
  }
}
EOF

# reload nginx with full conf
kill -TERM "$NGINX_STUB_PID"
nginx

############### start VersaTiles ############
log "Launching VersaTiles backend …"
exec su-exec vs:vs versatiles serve -p 8080 $VERSATILES_ARGS