#!/bin/bash

#docker run --rm versatiles-nginx:latest

docker run -it \
	-e DOMAIN=planetiler.versatiles.org \
	-e EMAIL=versatiles@michael-kreil.de \
	-e FRONTEND_VARIANT=dev \
	-e TILE_SOURCES="landcover-vectors.versatiles" \
	-v $(pwd)/data:/data \
	--tmpfs /tmp \
	-p 80:80 -p 443:443 \
	versatiles-nginx:latest
