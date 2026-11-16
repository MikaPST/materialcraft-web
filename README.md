<p align="center">
  <img src="https://raw.githubusercontent.com/storytold/materialcraft/main/assets/app-icon/hicolor/256x256/apps/ai.storyteller.materialcraft.png" width="128" height="128" alt="MaterialCraft application icon">
</p>

<h1 align="center">MaterialCraft Web — Docker Image</h1>
<p align="center">
  A community-maintained Docker image for
  <a href="https://github.com/storytold/materialcraft">MaterialCraft</a>,
  making its browser-based procedural material designer available through a self-hosted web interface.
  <br>
  Automated builds and image publication to GitHub Container Registry (GHCR).
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

The official MaterialCraft project provides a Rust-based, node-driven procedural material designer with a WebAssembly edition that can be hosted as a static website. This repository builds its official web application and packages the compiled assets into a lightweight NGINX image for simple self-hosting.

The goals are to:

- Build MaterialCraft Web from an **official upstream release tag**, not the moving `main` branch.
- Publish ready-to-run Docker images to GHCR for `linux/amd64` and `linux/arm64`.
- Automatically detect new official upstream releases, with manual and forced rebuild options.
- Create a matching GitHub Release **only after the multi-platform Docker image is pushed successfully**.
- Include optional upstream shared [craft-fonts](https://github.com/storytold/craft-fonts) input for complete release builds, with independent revision tracking.
- Provide ready-to-use Docker Compose and Unraid Community Applications deployment options.
- Maintain version-controlled `Dockerfile`, `nginx.conf`, `.dockerignore`, and GitHub Actions configuration independently from the upstream project.
- Preserve relevant source, asset and font license notices in the runtime image.

This is an independent packaging and distribution project. It is **not** an official MaterialCraft release or an upstream fork.

## How it works

MaterialCraft Web runs in the user's browser using WebAssembly. The Docker container serves the static application through NGINX; it is **not** a remote desktop, GPU processing service, or project-storage backend.

- **Node-based materials:** build procedural, tileable PBR materials through the visual node graph.
- **Preview and export:** inspect generated materials in the upstream 2D/3D views and export the supported material maps.
- **Browser-local processing:** the Rust application runs through WebAssembly in the browser; rendering performance depends on the client device.
- **Graphics:** use WebGPU when available, with WebGL2 as the fallback. `?webgl` forces the fallback renderer.
- **Local file handling:** project opening/saving and map exports use the browser's own file and download features.
- **Self-hosted delivery:** use your local network or a properly secured HTTPS reverse proxy.

The container stores neither project files nor generated material maps. Save and back up important work independently.

> [!NOTE]
> MaterialCraft's viewport requires a GPU graphics backend. **There is no CPU-only web rendering mode.** Browsers without WebGPU and WebGL2 cannot run the viewport. The upstream web application supports the `?webgl` flag.

## Docker image

The image is published to GitHub Container Registry after a successful build:

```text
ghcr.io/mikapst/materialcraft-web:latest
```

Each successfully packaged upstream release is also published with its official version tag, for example:

```text
ghcr.io/mikapst/materialcraft-web:vX.Y.Z
```

The `latest` tag is mutable. Use an existing version tag to stay on a selected upstream version, or a published image digest for strict repeatability.

### Option 1 — Docker Compose (recommended)

The repository includes a `docker-compose.yml` file:

```yaml
services:
  materialcraft-web:
    image: ghcr.io/mikapst/materialcraft-web:latest
    container_name: materialcraft-web
    ports:
      - "8080:8080"
    restart: unless-stopped
```

Start the application from the repository root:

```bash
docker compose up -d
```

Open the application in a browser:

```text
http://YOUR_SERVER_IP:8080
```

Replace `YOUR_SERVER_IP` with your server's IP address or hostname. For Docker running on your own computer, use `http://localhost:8080`.

#### Useful Compose commands

```bash
# Follow runtime logs
docker compose logs -f

# Update to the current image and recreate the container
docker compose pull
docker compose up -d

# Stop and remove the container
docker compose down
```

No `.env` file or persistent server-side application volume is required for normal use. The mapping `8080:8080` connects host port 8080 to container port 8080. Change its left-hand side (for example `8081:8080`) to use another host port.

### Option 2 — Run directly with Docker

Without Docker Compose:

```bash
docker pull ghcr.io/mikapst/materialcraft-web:latest

docker run -d \
  --name materialcraft-web \
  --restart unless-stopped \
  -p 8080:8080 \
  ghcr.io/mikapst/materialcraft-web:latest
```

Open `http://YOUR_SERVER_IP:8080` or `http://localhost:8080` on the Docker host.

Since processing occurs in the user's browser, adding CPU and memory to the Docker host does not automatically speed up complex material graphs.

### Network access and reverse proxies

The container serves HTTP on **port `8080`**. For remote access, configure a reverse proxy such as Traefik to terminate HTTPS and forward requests to the container.

The version-controlled NGINX configuration:

- Serves `.wasm` files as `application/wasm` and JavaScript as `text/javascript`.
- Enables gzip compression for WebAssembly, JavaScript, CSS and other compressible assets.
- Sets `Cache-Control: no-cache` for `index.html`, so the browser revalidates the application entry point after upgrades.
- Uses long-lived immutable caching **only for content-hashed static assets**; other WebAssembly and JavaScript files are revalidated.
- Provides `GET /healthz` and a Docker health check.
- Sends `X-Content-Type-Options: nosniff` and runs NGINX as the non-root `nginx` user.
- Responds with HTTP 404 for missing files rather than disguising missing WebAssembly assets as HTML.

WebGPU and clipboard APIs require a secure browser context (`https://` or `http://localhost`). On ordinary HTTP network addresses, WebGPU may be unavailable. Do not expose unencrypted HTTP directly to the public Internet.

Upstream Trunk uses relative asset paths (`public_url = "./"`), so it supports a domain root or URL prefix. If publishing below `/materialcraft/`, configure the reverse proxy to **strip the prefix before forwarding** to this root-mounted container, and keep relative URLs intact.

The current upstream web build does not require COOP/COEP isolation headers. If your infrastructure adds `Cross-Origin-Embedder-Policy: require-corp`, supply compatible Cross-Origin-Resource-Policy rules for the assets.

### Renderer selection and embedding

| URL option | Behaviour |
|---|---|
| No option | Use WebGPU if available, otherwise WebGL2. |
| `?webgl` | Force WebGL2, including for browser compatibility and automated smoke tests. |

Example:

```text
https://YOUR_DOMAIN/?webgl
```

MaterialCraft can also be embedded into a website using an iframe:

```html
<iframe
  src="https://YOUR_DOMAIN/"
  title="MaterialCraft procedural material designer"
  style="width:100%;height:720px;border:0;"
  allow="fullscreen; clipboard-read; clipboard-write"
  allowfullscreen>
</iframe>
```

For sandboxed iframes, allow scripts, same-origin operation, downloads and required popups. Check reverse proxy `X-Frame-Options` and `frame-ancestors` policies. See the [official hosting guide](https://github.com/storytold/materialcraft/blob/main/packaging/web/README.md).

## Repository structure

This repository keeps Docker packaging files independent of the upstream Rust source:

```text
materialcraft-web/
├── .github/
│   └── workflows/
│       └── publish-image.yml
├── .dockerignore
├── Dockerfile
├── nginx.conf
├── docker-compose.yml
└── README.md
```

| File | Purpose |
|---|---|
| `Dockerfile` | Defines the minimal NGINX runtime, OCI metadata, and non-root execution. |
| `nginx.conf` | Handles WebAssembly, caching, compression, security headers, and health checks. |
| `.dockerignore` | Limits the temporary build context to the static web assets, legal notices and required configuration. |
| `docker-compose.yml` | Provides a ready-to-use deployment configuration. |
| `.github/workflows/publish-image.yml` | Detects official upstream releases, compiles Rust/Trunk, publishes GHCR images and matching GitHub Releases. |
| `README.md` | Documents the project, build architecture, deployment, automation and upstream attribution. |

### Docker build architecture

MaterialCraft compiles its official WebAssembly application **once in GitHub Actions**, then packages the same site as NGINX images for AMD64 and ARM64. No Rust compilation is repeated inside Docker.

```text
GitHub Actions workspace/
├── packaging/                  # MikaPST/materialcraft-web
│   ├── Dockerfile
│   ├── nginx.conf
│   ├── .dockerignore
│   ├── docker-compose.yml
│   └── README.md
├── upstream/                   # storytold/materialcraft at the official release tag
├── craft-fonts/                # storytold/craft-fonts at the current main commit
└── docker-context/             # generated during the workflow
    ├── Dockerfile              # copied from packaging/
    ├── nginx.conf              # copied from packaging/
    ├── .dockerignore           # copied from packaging/
    ├── site/                   # generated from upstream/dist/web/
    └── legal/                  # upstream and font notices
```

The build proceeds as follows:

1. GitHub Actions checks out this packaging repository and validates its version-controlled files.
2. It resolves the latest official MaterialCraft release, or an explicitly requested `upstream_tag`.
3. The workflow skips already published versions on ordinary scheduled/manual runs, unless a force rebuild or monitored packaging update requires another build.
4. It checks out `storytold/materialcraft` at the exact official release tag and `storytold/craft-fonts` at its own `main` revision.
5. Rust and `wasm32-unknown-unknown` are installed, followed by Trunk.
6. `trunk build --release` runs in `upstream/apps/materialcraft-web` using `CRAFT_FONTS_DIR`. The upstream `index.html` selects the optimized Cargo **`wasm-release`** profile.
7. The workflow validates `upstream/dist/web/index.html`, JavaScript and WebAssembly outputs and relative asset URLs.
8. The official web-packaging **24 MiB WASM size gate** is retained, so a size regression is detected before Docker publication.
9. It assembles `docker-context/` from the compiled files and copies the versioned Docker packaging configuration plus source and font license notices.
10. Docker Buildx publishes the same static site in `linux/amd64` and `linux/arm64` runtime images.
11. **Only after GHCR publication succeeds**, the matching GitHub Release is created or updated.

The `docker-context/`, `site/`, `legal/`, `upstream/` and `craft-fonts/` build directories are temporary GitHub Actions workspace content. They are **not committed** to this packaging repository.

> [!NOTE]
> MaterialCraft's official static-site packaging script enforces a 24 MiB maximum for individual `.wasm` files, to remain below Cloudflare Pages/Workers' 25 MiB single-file limit. The Docker image is not itself subject to this limit; this workflow deliberately retains the upstream web packaging guardrail. A future release exceeding it will fail until the build or policy is updated.

## Automated builds

GitHub Actions checks [official MaterialCraft releases](https://github.com/storytold/materialcraft/releases) and builds the selected official tag.

| Trigger | Behaviour |
|---|---|
| Daily schedule (`03:47 UTC`) | Checks the latest official upstream release; skips it when already packaged. |
| Manual workflow dispatch | Builds the latest official release, or the tag supplied in `upstream_tag`. |
| Force rebuild | Rebuilds an already published version with `force_rebuild: true`. |
| Packaging changes on `main` | Rebuilds the latest official upstream release after changes to `Dockerfile`, `nginx.conf`, `.dockerignore`, `docker-compose.yml`, `README.md` or the workflow. |

### Published tags

Each successful build publishes the following GHCR tags:

- `latest` — the most recently successfully published image.
- `<upstream-version>` — the exact upstream release tag, such as `vX.Y.Z`.
- `upstream-<commit>` — the first **12 characters** of the selected official upstream source commit.

The image supports `linux/amd64` and `linux/arm64`. The WebAssembly site is compiled once and shipped unchanged for both architectures.

MaterialCraft's source is checked out at a specific release tag. The separately maintained `craft-fonts` checkout follows its `main` branch, so rebuilding the same MaterialCraft tag may change the embedded font assets. Both exact source commits are preserved in build metadata and GitHub Release notes.

### GitHub Releases

Once Docker Buildx has successfully pushed the image to GHCR, the workflow creates or updates a [GitHub Release](https://github.com/MikaPST/materialcraft-web/releases) with the matching upstream tag.

Each release includes:

- The official upstream version, release name, source link and publication date.
- Official upstream release notes.
- The exact MaterialCraft source commit and the selected `craft-fonts` commit.
- The published Docker image tags.
- The supported architectures (`linux/amd64` and `linux/arm64`).
- The Docker image digest, when returned by Buildx.
- An independent-packaging notice distinguishing this image from the official upstream release.

The Release badge at the top of this README reflects the latest published GitHub Release.

Ordinary scheduled and manual runs skip versions that already have a release in this repository. To rebuild one, open **Actions → Build and publish MaterialCraft Web → Run workflow** and enable `force_rebuild`. Updates to monitored packaging files on `main` also trigger a rebuild.

> [!IMPORTANT]
> A matching GitHub Release is created or updated **only after** a successful GHCR push.
>
> `latest` is mutable, and forced rebuilds can also replace the image behind an existing version tag. Use an immutable image digest when exact deployment identity is important.

## Unraid Community Applications

MaterialCraft Web can be deployed on Unraid using the independently maintained [MikaPST/unraid-community-apps](https://github.com/MikaPST/unraid-community-apps) template.

- **Unraid Community Applications repository:** [MikaPST/unraid-community-apps](https://github.com/MikaPST/unraid-community-apps)
- **MaterialCraft Web template:** [materialcraft-web.xml](https://github.com/MikaPST/unraid-community-apps/blob/main/templates/materialcraft-web.xml)
- **Container image:** `ghcr.io/mikapst/materialcraft-web:latest`
- **Container port:** `8080`
- **Default host port in the Unraid XML:** `8088` (adjustable).

The Unraid template is maintained separately from this Docker packaging repository. The Docker Compose configuration uses host port `8080` by default; the Unraid XML template uses `8088` to reduce port conflicts.

Project files and generated material maps are not stored in Unraid appdata. Save and back up browser-generated files independently.

## Upstream project

MaterialCraft is an open-source procedural material designer developed by the ArtCraft Team and contributors.

- **Source code:** [storytold/materialcraft](https://github.com/storytold/materialcraft)
- **Official website:** [getartcraft.com/apps/materialcraft](https://getartcraft.com/apps/materialcraft)
- **Official web hosting guide:** [packaging/web/README.md](https://github.com/storytold/materialcraft/blob/main/packaging/web/README.md)
- **Official web packaging script:** [packaging/web/package.sh](https://github.com/storytold/materialcraft/blob/main/packaging/web/package.sh)
- **Shared font resources:** [storytold/craft-fonts](https://github.com/storytold/craft-fonts)
- **Official releases:** [MaterialCraft releases](https://github.com/storytold/materialcraft/releases)

The MikaPST image and GitHub Release track official upstream versions but represent independently maintained Docker packaging, **not official MaterialCraft distributions**.

## License and attribution

MaterialCraft's source code is dual-licensed under the **MIT License or Apache License 2.0**, at the user's option. Copyright belongs to the ArtCraft Team and MaterialCraft contributors.

The packaging workflow preserves upstream `LICENSE-MIT`, `LICENSE-APACHE`, `NOTICE`, and `ATTRIBUTION.md` in the runtime image's `/licenses/` directory. It also preserves available `OFL.txt` font license notices and the shared font attribution document for the fonts used during compilation.

- [Upstream MIT License](https://github.com/storytold/materialcraft/blob/main/LICENSE-MIT)
- [Upstream Apache License 2.0](https://github.com/storytold/materialcraft/blob/main/LICENSE-APACHE)
- [Upstream NOTICE](https://github.com/storytold/materialcraft/blob/main/NOTICE)
- [Upstream asset attribution](https://github.com/storytold/materialcraft/blob/main/ATTRIBUTION.md)
- [Shared font repository](https://github.com/storytold/craft-fonts)

The upstream software license does not automatically determine the license of the independent packaging files maintained here. Refer to this repository's own `LICENSE` file, if provided, for their terms.

The ArtCraft name, wordmark and logos are trademarks subject to their separate rights and [upstream branding terms](https://github.com/storytold/materialcraft/blob/main/docs/brand/LICENSE-brand.txt).

## Disclaimer

MaterialCraft is under active development. Features, browser compatibility, rendering capabilities and export behaviour may change between builds. Test new images and maintain independent copies of important projects and generated assets.

This independent community packaging is not affiliated with, sponsored by, or endorsed by the official MaterialCraft or ArtCraft maintainers.
