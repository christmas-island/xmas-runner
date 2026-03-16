# xmas-runner

Purpose-built GitHub Actions self-hosted runner Docker image for the christmas-island GitHub org.

## Project structure

- `Dockerfile` — Multi-arch runner image (ubuntu:24.04 base)
- `entrypoint.sh` — Runner registration, startup, and graceful shutdown
- `docker-compose.yml` — Local deployment configuration
- `tests/tools.bats` — Bats tests verifying all pre-installed tools
- `.github/workflows/ci.yml` — PR build + test
- `.github/workflows/publish.yml` — Build and push to GHCR on main/tags
- `.releaserc.yaml` — semantic-release with conventionalcommits
- `ANALYSIS.md` — CI audit of all christmas-island repos (reference)

## Conventions

- Commit messages: conventional commits (`feat:`, `fix:`, `chore:`, etc.)
- Dockerfile is organized by tiers (core, runtimes, build tools, extras)
- Version pins use ARG for easy updates
- Multi-arch: all binary downloads handle both amd64 and arm64
- Docker-outside-of-Docker pattern (mount host socket, no daemon in image)

## Key design decisions

- Image is ~2-3GB vs GitHub's ~50GB full runner — we only include tools the org actually uses
- Ephemeral runners by default (one job, then exit)
- GITHUB_PAT auto-registration preferred over manual RUNNER_TOKEN
- Rust installed via rustup, Go via official tarball, Node via NodeSource
