<p align="center">
  <img src="https://raw.githubusercontent.com/storytold/materialcraft/main/assets/app-icon/hicolor/256x256/apps/ai.storyteller.materialcraft.png" width="128" height="128" alt="MaterialCraft application icon">
</p>

<h1 align="center">MaterialCraft Web — Docker Image</h1>
<p align="center">
  A community-maintained Docker image for
  <a href="https://github.com/storytold/materialcraft">MaterialCraft</a>,
  providing its browser-based procedural material designer through a self-hosted web interface.
  <br>
  Build automation and image publication to GitHub Container Registry (GHCR).
</p>
<p align="center">
  <a href="https://github.com/MikaPST/materialcraft-web/actions/workflows/publish-image.yml">
    <img src="https://github.com/MikaPST/materialcraft-web/actions/workflows/publish-image.yml/badge.svg" alt="Build and publish MaterialCraft Web">
  </a>
  <a href="https://github.com/MikaPST/materialcraft-web/releases/latest">
    <img src="https://img.shields.io/github/v/release/MikaPST/materialcraft-web?label=Release&logo=github&color=blue" alt="Latest Release">
  </a>
  <a href="https://github.com/MikaPST/materialcraft-web/pkgs/container/materialcraft-web">
    <img src="https://ghcr-badge.egpl.dev/mikapst/materialcraft-web/latest_tag?trim=major&label=GHCR" alt="GHCR image tag">
  </a>
  <a href="docker-compose.yml">
    <img src="https://img.shields.io/badge/Docker%20Compose-ready-2496ED?logo=docker&logoColor=white" alt="Docker Compose configuration">
  </a>
</p>

---

## Why this repository?

The official MaterialCraft project provides a WebAssembly-based version that can be hosted as a static website. This repository packages the web application into a Docker image to simplify self-hosting.

The goals are to:

- Publish a matching GitHub Release only after the Docker build and push succeed.
- Build the MaterialCraft Web application from the upstream source code.
- Publish a ready-to-run Docker image to GHCR.
- Automatically rebuild the image every week to incorporate upstream changes.
- Provide a convenient deployment option for Unraid Community Applications.
- Offer a simple Docker Compose configuration for users who prefer managing containers with Compose.
- Keep the packaging and deployment configuration separate from the upstream MaterialCraft project.

This is a packaging and distribution project, not a fork intended to develop a separate material-design application.

## How it works

MaterialCraft Web runs directly in the user's browser using WebAssembly. The Docker container serves the static web application through NGINX; it does not provide a remote Linux desktop or a server-side material-processing service.

- **Browser-based interface:** use MaterialCraft's node-based procedural material editor in a modern web browser.
- **WebAssembly application:** the Rust application is compiled to WebAssembly and runs client-side.
- **Web graphics:** the web runner uses WebGPU with a WebGL2 fallback, depending on browser support.
- **Browser file I/O:** opening and saving project files, as well as exporting material maps, use the browser's file and download capabilities.
- **Self-hosted:** run the static application on your own server and access it over your local network or through a properly configured reverse proxy.

Material creation and processing run in the browser. The container serves the application files rather than acting as a material-processing backend or persistent document-storage service. Project files and exported maps are handled through the browser's file and download capabilities.

WebGPU requires a secure browser context: use HTTPS when accessing the application remotely, or `http://localhost` for local testing. MaterialCraft can fall back to WebGL2 when WebGPU is unavailable; the upstream documentation also provides the `?webgl` URL flag to force that renderer.

## Docker image

The image is published to GitHub Container Registry:

```text
ghcr.io/mikapst/materialcraft-web:latest
```

Each official upstream release is also published under its exact version tag, for example:

```text
ghcr.io/mikapst/materialcraft-web:vX.Y.Z
```

Use a versioned tag if you want to keep a deployment on a specific release. The `latest` tag updates when an image is published.

### Option 1 — Docker Compose (recommended)

A `docker-compose.yml` file is provided at the root of this repository. It is the simplest way to start and maintain MaterialCraft Web with Docker Compose.

```yaml
services:
  materialcraft-web:
    image: ghcr.io/mikapst/materialcraft-web:latest
    container_name: materialcraft-web
    ports:
      - "8080:8080"
    restart: unless-stopped
```

From the repository root, start the application with:

```bash
docker compose up -d
```

Open the application in your browser:

```text
http://YOUR_SERVER_IP:8080
```

Replace `YOUR_SERVER_IP` with the IP address or hostname of your server. If Docker is running on your own computer, you can use `http://localhost:8080`.

#### Useful Compose commands

```bash
# View container logs
docker compose logs -f

# Pull the latest image and recreate the container
docker compose pull
docker compose up -d

# Stop and remove the container
docker compose down
```

No `.env` file or persistent volume is required for this basic setup. The host port is configured in `docker-compose.yml`; by default, port `8080` on the host is mapped to port `8080` in the container. To use a different host port, change the left-hand side of the mapping. For example, `8081:8080` exposes the application on host port `8081`.

### Option 2 — Run directly with Docker

If you prefer not to use Docker Compose, you can run the container directly:

```bash
docker pull ghcr.io/mikapst/materialcraft-web:latest

docker run -d \
  --name materialcraft-web \
  --restart unless-stopped \
  -p 8080:8080 \
  ghcr.io/mikapst/materialcraft-web:latest
```

Open the application at:

```text
http://YOUR_SERVER_IP:8080
```

Material generation and rendering are performed client-side. Browser performance and available memory therefore depend on the device running the browser, not only on the Docker host.

### Network access and reverse proxies

The container listens for HTTP traffic on port `8080`. For external access, use a reverse proxy such as Traefik to terminate HTTPS and forward requests to the container over HTTP.

Do not expose an unencrypted HTTP port directly to the public Internet. Restrict access to your intended network or protect external access with HTTPS and appropriate access controls.

## Automated builds

GitHub Actions checks the official [MaterialCraft releases](https://github.com/storytold/materialcraft/releases), builds the WebAssembly application from the selected upstream tag and publishes the image to GHCR.

| Trigger | Behaviour |
|---|---|
| Weekly schedule | Checks the latest official MaterialCraft release and builds it if it has not already been published here |
| Manual workflow dispatch | Builds the latest official release, or a specified `upstream_tag` |
| Force rebuild | Rebuilds an already published version with `force_rebuild: true` |
| Changes to packaging files on `main` | Rebuilds the current official upstream release with the updated workflow |

### Published tags

- `latest` — the latest successfully published image (mutable tag).
- `<upstream-version>` — the exact official upstream tag, for example `vX.Y.Z`.
- `upstream-<commit>` — the upstream source commit used for the image (first 12 hexadecimal characters).

The image targets both `linux/amd64` and `linux/arm64`. The workflow checks out **the official upstream release tag**, rather than compiling `main` as the versioned source.

### GitHub Releases

After a successful Docker build and GHCR push, the workflow creates or updates a [GitHub Release](https://github.com/MikaPST/materialcraft-web/releases) matching the upstream tag. It includes the upstream release notes, source link and commit, Docker tags, supported architectures and (when available) the published image digest.

The Release badge at the top of this README updates automatically. Scheduled runs skip versions already released here. You can force a rebuild from **Actions → Build and publish MaterialCraft Web → Run workflow**.

> [!IMPORTANT]
> A GitHub Release is created only after the Docker image has been successfully published. The `latest` tag may change after a rebuild; pin a versioned image tag for a stable deployment. Auxiliary source repositories (for example `craft-fonts`) may be checked out separately and are not necessarily pinned to the upstream release commit.

## Unraid Community Applications

This image is intended to be distributed through the maintainer's existing Unraid Community Applications repository.

The Unraid template references the published GHCR image and provides configuration for the web port.

- **Unraid Community Applications repository:** [MikaPST/unraid-community-apps](https://github.com/MikaPST/unraid-community-apps)
- **MaterialCraft Web template:** to be added when the template is published.

This repository contains the image build, publication workflow and Docker Compose configuration. The Unraid Community Applications template is maintained separately.
- **Template:** [materialcraft-web.xml](https://github.com/MikaPST/unraid-community-apps/blob/main/templates/materialcraft-web.xml)

## Upstream project

MaterialCraft is an open-source, node-based procedural material designer written in Rust by the ArtCraft Team and its contributors. It is designed to create tileable PBR materials from procedural nodes, inspect them in 2D and 3D views, and export material maps for use in other tools.

- **Source code:** [storytold/materialcraft](https://github.com/storytold/materialcraft)
- **Official website:** [getartcraft.com/apps/materialcraft](https://getartcraft.com/apps/materialcraft)
- **Official web build instructions:** [MaterialCraft web packaging](https://github.com/storytold/materialcraft/blob/main/packaging/web/README.md)
- **Official releases:** [MaterialCraft releases](https://github.com/storytold/materialcraft/releases)

The upstream web application is built with Trunk from `apps/materialcraft-web`. This repository builds that browser application from upstream source and packages the generated static files in an NGINX image. It does not modify the MaterialCraft application itself.

The MikaPST GitHub Release tracks the upstream version but represents independent Docker packaging, not an official MaterialCraft distribution.

## License and attribution

MaterialCraft is dual-licensed under the **MIT License or Apache License 2.0**, at the user's option. Copyright belongs to the ArtCraft Team and MaterialCraft contributors.

The upstream project includes third-party components and bundled assets under their own licenses. The upstream `NOTICE` and `ATTRIBUTION.md` files identify these components and their applicable terms. These notices and license files must be preserved when redistributing the application.

The ArtCraft name, wordmark and logos are trademarks of the ArtCraft Team and are not covered by the software license. Refer to the upstream `docs/brand/LICENSE-brand.txt` for their terms.

The Docker packaging files in this repository are maintained separately from the upstream application. This repository does not claim ownership of MaterialCraft or its bundled assets.

## Disclaimer

This is an independent community packaging project and is not affiliated with, endorsed by, or sponsored by the ArtCraft Team.

MaterialCraft is provided by its upstream authors under its own license and development status. Use this Docker image at your own risk and consult the official repository for the latest information, limitations and notices.
