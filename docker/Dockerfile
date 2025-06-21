# ---------- build stage ----------
FROM alpine:latest AS builder

# runtime deps for versatiles build script
RUN apk add --no-cache curl ca-certificates sudo

# download the static VersaTiles binary
RUN curl -Ls https://github.com/versatiles-org/versatiles-rs/raw/main/scripts/install-unix.sh | sudo sh

# ---------- runtime stage ----------
FROM alpine:latest
LABEL maintainer="versatiles@michael-kreil.de"

ENV UID=10001 GID=10001 \
    DOMAIN="" \
    EMAIL="" \
    FRONTEND_VARIANT="" \
    TILE_SOURCES="" \
    CACHE_SIZE_KEYS="" \
    CACHE_SIZE_MAX="" \
    PATH="$PATH:/scripts"

# core packages
RUN apk add --no-cache nginx certbot certbot-nginx curl bash su-exec tzdata tini gzip && \
    mkdir -p /var/cache/nginx /etc/nginx/templates /data && \
    addgroup -g "$GID" vs && adduser -D -s /sbin/nologin -G vs -u "$UID" vs

# copy VersaTiles binary from builder
COPY --from=builder /usr/local/bin/versatiles /usr/local/bin/versatiles

# copy entrypoint
COPY scripts/ /scripts/
RUN chmod +x /scripts/*.sh

VOLUME ["/data"]
EXPOSE 80 443

HEALTHCHECK --interval=30s --timeout=5s --retries=3 CMD curl -f http://127.0.0.1:8090/_nginx_status || exit 1

ENTRYPOINT ["/sbin/tini","--","entrypoint.sh"]
