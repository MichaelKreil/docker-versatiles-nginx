## Build (multi‑arch)

```bash
docker buildx build --platform linux/amd64,linux/arm64 -t versatiles-nginx:latest .
```

## Run

```bash
docker run -d --name versatiles-nginx \
  -e DOMAIN=maps.example.com \
  -e EMAIL=admin@example.com \
  -e FRONTEND=dev \
  -e TILE_SOURCES="osm_europe.versatiles" \
  -v $(pwd)/data:/data \
  --read-only --tmpfs /tmp \
  -p 80:80 -p 443:443 \
  versatiles-nginx:latest
```

## Environment variables

| Variable              | Required | Default        | Purpose                                                                                                                                                   |
|-----------------------|----------|----------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------|
| `DOMAIN`              | **Yes**  | –              | Domainname that the container should serve and for which Certbot will obtain a Let’s Encrypt certificate.                                                 |
| `EMAIL`               | **Yes**  | –              | Contact e‑mail passed to Certbot during ACME registration.                                                                                                |
| `FRONTEND`            | No       | `default`      | Selects the UI bundle fetched from the latest VersaTiles Frontend release. One of `default` (default), `dev` (developer), `min` (extra‑small), or `none`. |
| `TILE_SOURCES`        | No       | `""`           | Comma‑separated list of `.versatiles` files to serve. Missing files are auto‑downloaded from `download.versatiles.org`.                                   |
| `CERT_MIN_DAYS`       | No       | `30`           | Skip ACME at startup if existing cert is valid for more than this many days.                                                                              |
| `CERT_RENEW_INTERVAL` | No       | `43200` (12 h) | Interval in seconds for the background `certbot renew` loop.                                                                                              |

## Volumes

The container expects a single bind‑mount at **/data** where it stores everything that must survive restarts:

```
/data
 ├─ certificates/   # Let’s Encrypt keys & certs
 ├─ frontend/       # downloaded UI bundle (if FRONTEND ≠ "none")
 ├─ log/            # nginx access & error logs
 ├─ static/         # additional static files that will be served.
 │                  # Files in this folder are prioritized over static files from the standard frontend.
 └─ tiles/          # *.versatiles map‑tile archives
                    # Add files here if there are not available from download.versatiles.org
```

Bind it when you run the container:

```bash
-v $(pwd)/data:/data
```

## Reset Cache

```bash
docker exec versatiles-nginx nginx_clear.sh
```

## Healthcheck

`docker ps` will show `healthy` when nginx responds on `/_nginx_status`.
