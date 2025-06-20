#!/bin/bash

docker run --rm versatiles-nginx:latest


# docker run -d --name maps \
#   -e DOMAIN=maps.example.com \
#   -e EMAIL=admin@example.com \
#   -e FRONTEND_VARIANT=frontend-dev \
#   -e TILE_SOURCES="osm_europe.versatiles" \
#   -v $(pwd)/data:/data \
#   --read-only --tmpfs /tmp \
#   -p 80:80 -p 443:443 \
#   versatiles-nginx:latest
