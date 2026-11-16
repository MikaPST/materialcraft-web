# syntax=docker/dockerfile:1
# MaterialCraft Web: static NGINX packaging only.
# The official Rust/Trunk build is compiled once in GitHub Actions, not in Docker.
# Build context: generated docker-context/ with site/, legal/, nginx.conf and Dockerfile.
ARG NGINX_VERSION=1.28-alpine
FROM nginx:${NGINX_VERSION}

ARG MATERIALCRAFT_COMMIT=unknown
ARG CRAFT_FONTS_COMMIT=unknown
ARG MATERIALCRAFT_VERSION=unknown

LABEL org.opencontainers.image.title="MaterialCraft Web" \
      org.opencontainers.image.description="Community-maintained browser build of MaterialCraft" \
      org.opencontainers.image.source="https://github.com/storytold/materialcraft" \
      org.opencontainers.image.version="${MATERIALCRAFT_VERSION}" \
      org.opencontainers.image.revision="${MATERIALCRAFT_COMMIT}" \
      io.mikapst.materialcraft.craft-fonts-revision="${CRAFT_FONTS_COMMIT}"

# Replace the full configuration to support unprivileged NGINX and consistent headers.
COPY nginx.conf /etc/nginx/nginx.conf
COPY site/ /usr/share/nginx/html/
COPY legal/ /usr/share/nginx/html/licenses/

# Port 8080 and all writable runtime paths are compatible with the non-root nginx user.
USER nginx
EXPOSE 8080
ENTRYPOINT []
CMD ["nginx", "-g", "daemon off;"]
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD wget -q -O /dev/null http://127.0.0.1:8080/healthz || exit 1
