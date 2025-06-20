#!/bin/bash

#docker run --rm versatiles-nginx:latest

docker run -it --rm --name versatiles-nginx \
	-e DOMAIN=planetiler.versatiles.org \
	-e EMAIL=versatiles@michael-kreil.de \
	-e FRONTEND_VARIANT=dev \
	-e TILE_SOURCES="osm.planetiler.versatiles" \
	-v $(pwd)/data:/data \
	--tmpfs /tmp \
	-p 80:80 -p 443:443 \
	versatiles-nginx:latest
