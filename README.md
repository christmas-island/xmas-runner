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

## Apple Silicon setup (M1/M2/M3/M4)

The image is built for `linux/amd64`. On Apple Silicon Macs you need a few extra steps to match the CI x86_64 environment and work around Docker Desktop quirks.

### Step-by-step

1. **Clone the repo and copy the env file**
   ```bash
   git clone https://github.com/christmas-island/xmas-runner.git
   cd xmas-runner
   cp .env.example .env
   ```

2. **Get a registration token or PAT**

   **Option A — Registration token (quick, expires ~1hr)**
   - GitHub org → Settings → Actions → Runners → **New self-hosted runner**
   - Copy the token that starts with `A`

   **Option B — Classic PAT (recommended for persistent runners)**
   - Go to https://github.com/settings/tokens → **Generate new token (classic)**
   - Scopes needed: `admin:org`
   - ⚠️ **Fine-grained PATs do NOT work** for self-hosted runner management — you must use a classic PAT

3. **Edit `.env`**
   ```
   # Use one of:
   RUNNER_TOKEN=AXXXXXXXXX      # from GitHub UI (Option A)
   GITHUB_PAT=ghp_xxxxxxxxx     # classic PAT (Option B)

   RUNNER_LABELS=self-hosted,linux,X64,xmas-isle,xmas-runner
   RUNNER_NAME=my-mac-runner    # unique name if running multiple
   ```

4. **Start the runner**
   ```bash
   docker compose up -d
   ```

5. **Verify it connected**
   ```bash
   docker logs -f xmas-runner-runner-1
   # Look for: "Connected to GitHub"
   ```

The `docker-compose.yml` already includes the Apple Silicon fixes:
- `platform: linux/amd64` — runs via Rosetta to match CI x86_64 environment
- `privileged: true` + entrypoint chmod — fixes Docker socket permissions on Docker Desktop Mac
- No `runner-work` volume mount — avoids permission denied errors on Docker Desktop

## Troubleshooting

### Platform mismatch (`linux/amd64 does not match detected host platform linux/arm64`)
The `platform: linux/amd64` line in `docker-compose.yml` must be set. This is already the default in this repo but if you see this warning, verify it's uncommented.

### Runner not picking up jobs
Check that your runner's labels match the `runs-on` value in your workflow. For christmas-island workflows, the runner must have the `xmas-isle` label:
```yaml
runs-on: [self-hosted, linux, X64, xmas-isle]
```
Check registered labels in **GitHub → Settings → Actions → Runners**.

### "A session for this runner already exists"
The runner name is already registered but the container is gone. Either:
- Change `RUNNER_NAME` in `.env` to something unique
- Or go to GitHub → Settings → Actions → Runners → find the ghost runner → Remove

### Permission denied on `_work` directory
Don't mount a named volume at `/home/runner/actions-runner/_work`. Docker Desktop for Mac's volume ownership doesn't match the runner user inside the container. The `runner-work` volume mount has been removed from `docker-compose.yml` for this reason.

### Docker socket permission denied inside container
Docker Desktop for Mac creates the socket as `root:root`. The entrypoint in `docker-compose.yml` runs `sudo chmod 666 /var/run/docker.sock` before starting the runner to fix this. If you see socket permission errors, make sure you're using the `entrypoint` override and `privileged: true` from `docker-compose.yml`.

### Runner token expired
Registration tokens from the GitHub UI expire in ~1 hour. If your container restarts and fails to register, get a new token — or switch to `GITHUB_PAT` with a classic PAT (`admin:org` scope) which auto-renews on each start.

## Building locally

```bash
# Build for current architecture
docker build -t xmas-runner:local .

# Build multi-arch
docker buildx build --platform linux/amd64,linux/arm64 -t xmas-runner:local .

# Run tests
docker run --rm --entrypoint "" xmas-runner:local bats tests/tools.bats
```
