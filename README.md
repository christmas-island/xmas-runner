# xmas-runner

Purpose-built GitHub Actions self-hosted runner for the **christmas-island** GitHub org. Contains only the tools our repos actually use — ~2-3GB instead of GitHub's ~50GB full runner image.

## Quick start

```bash
# Clone and configure
git clone https://github.com/christmas-island/xmas-runner.git
cd xmas-runner
cp .env.example .env  # Edit with your PAT and org settings

# Run with docker compose
docker compose up -d
```

Or run directly:

```bash
docker run -d \
  --name xmas-runner \
  -e GITHUB_PAT="ghp_your_token" \
  -e RUNNER_SCOPE="org" \
  -e RUNNER_TARGET="christmas-island" \
  -e RUNNER_NAME="my-runner" \
  -e RUNNER_LABELS="self-hosted,linux,x64,xmas-runner" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  ghcr.io/christmas-island/xmas-runner:latest
```

## Environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| `GITHUB_PAT` | — | Personal access token with `admin:org` scope (for auto-registration) |
| `RUNNER_TOKEN` | — | Direct registration token (alternative to PAT) |
| `RUNNER_SCOPE` | — | `org` or `repo` (required with PAT) |
| `RUNNER_TARGET` | — | Org name or `owner/repo` (required with PAT) |
| `RUNNER_NAME` | hostname | Display name in GitHub |
| `RUNNER_LABELS` | `self-hosted,linux,x64,xmas-runner` | Comma-separated labels |
| `RUNNER_GROUP` | `default` | Runner group name |
| `EPHEMERAL` | `true` | Exit after one job (recommended) |
| `GITHUB_URL` | `https://github.com` | Base URL (change for GHE) |

## Pre-installed tools

### Tier 1 — Core
git, curl, jq, bash, ca-certificates, wget, zip, unzip, sudo

### Tier 2 — Language runtimes
- **Go** 1.24 (official tarball)
- **Node.js** 22 LTS + npm + yarn
- **Python** 3.12 + pip
- **Rust** stable (via rustup) + clippy + rustfmt

### Tier 3 — Build & lint tools
- **Docker CLI** + Buildx plugin (host socket, no daemon)
- **QEMU** user-static (cross-platform builds)
- **goreleaser**, **prek** (pre-commit-rs)
- **hadolint**, **shellcheck**, **shfmt**
- **golangci-lint**
- **bats-core**
- **OpenTofu**, **tflint**, **terraform-docs**

### Tier 4 — Extras
- PostgreSQL client (psql, pg_isready)
- MySQL client
- yarn

## Adding to your GitHub org

1. Create a PAT with `admin:org` scope (for org-level runners) or `repo` scope (for repo-level)
2. Set the PAT as `GITHUB_PAT` environment variable
3. Set `RUNNER_SCOPE=org` and `RUNNER_TARGET=christmas-island`
4. Start the container — it auto-registers with GitHub
5. The runner appears in **Settings → Actions → Runners**

For repo-level runners, use `RUNNER_SCOPE=repo` and `RUNNER_TARGET=christmas-island/repo-name`.

## Apple Silicon notes

The image is built for `linux/amd64` and `linux/arm64`. On Apple Silicon Macs:

- **Native arm64**: Works natively, best performance
- **amd64 via Rosetta**: Add `platform: linux/amd64` in docker-compose.yml (slower but matches CI environment)
- Docker Desktop enables Rosetta by default on macOS

## Building locally

```bash
# Build for current architecture
docker build -t xmas-runner:local .

# Build multi-arch
docker buildx build --platform linux/amd64,linux/arm64 -t xmas-runner:local .

# Run tests
docker run --rm --entrypoint "" xmas-runner:local bats tests/tools.bats
```
