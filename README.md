### Build (multi‑arch)

```bash
docker buildx build --platform linux/amd64,linux/arm64 -t versatiles-nginx:latest .
````

### Run

```bash
docker run -d --name maps \
  -e DOMAIN=maps.example.com \
  -e EMAIL=admin@example.com \
  -e FRONTEND_VARIANT=frontend-dev \
  -e TILE_SOURCES="osm_europe.versatiles" \
  -v $(pwd)/data:/data \
  --read-only --tmpfs /tmp \
  -p 80:80 -p 443:443 \
  versatiles-nginx:latest
```

### Healthcheck

`docker ps` will show `healthy` when nginx responds on `/_nginx_status`.
