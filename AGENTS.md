# xmas-runner

Purpose-built GitHub Actions self-hosted runner image for the christmas-island
org (~2–3GB vs GitHub's ~50GB). Tools the org actually uses only. See
[README.md](README.md) for env vars, registration, Apple Silicon notes, and
troubleshooting; [ANALYSIS.md](ANALYSIS.md) is the CI tooling audit that
justified the tool list.

## Layout

- `Dockerfile` — multi-arch runner image (ubuntu:24.04), tiers: core →
  runtimes → build/lint → extras; version pins are `ARG`s
- `entrypoint.sh` — registration, startup, graceful shutdown
- `docker-compose.yml` — local deploy: runner + `docker:28-dind` sidecar
- `tests/tools.bats` — Bats suite asserting every preinstalled tool
- `.github/workflows/{ci,publish}.yml` — PR build+test; GHCR push on main/tags
- `.releaserc.yaml` — semantic-release (conventional commits)

## Required

- Conventional commits (`feat:`, `fix:`, `chore:`, …) — release notes and
  version come from them.
- Dockerfile is tier-organized; multi-arch binary downloads must handle both
  amd64 and arm64.
- Compose runs **Docker-in-Docker**, not host-socket DooD: the image ships
  Docker CLI + Buildx only (no daemon), `DOCKER_HOST=tcp://dind:2375`, and
  `runner-work` is shared so bind mounts resolve inside the DinD daemon.
  This is the macOS Docker Desktop workaround (PR #2). Do not "simplify"
  back to mounting `/var/run/docker.sock` without re-testing on a Mac.
- Ephemeral runners are the recommended mode (one job, then exit).
  `GITHUB_PAT` auto-registration needs a **classic** PAT with `admin:org`
  (fine-grained PATs cannot manage runners).

```bash
# Test the image tool inventory
docker run --rm --entrypoint "" xmas-runner:local bats tests/tools.bats

# Local multi-arch build
docker buildx build --platform linux/amd64,linux/arm64 -t xmas-runner:local .
```

Pre-commit: shellcheck + hadolint (`.pre-commit-config.yaml`).

## Key libraries / tools

Runtimes: Go (tarball), Node 22 (NodeSource), Python 3.12, Rust (rustup).
Build/lint: Docker CLI + Buildx, QEMU, goreleaser, prek, hadolint,
shellcheck, shfmt, golangci-lint, bats-core, OpenTofu, tflint,
terraform-docs.

## Maintaining this index

- Update the affected `AGENTS.md` files in the same change when paths,
  responsibilities, commands, dependencies, or conventions change.
- Keep indexes brief: record semantic entry points and non-obvious
  constraints; link to existing documentation instead of duplicating it.
- Add a directory index only when it provides useful navigation beyond its
  parent; omit generated, vendored, and fixture trees.
- Do not add `CLAUDE.md` files; Claude Code reads `AGENTS.md` natively, and
  a `CLAUDE.md` anywhere in the tree stops every `AGENTS.md` from loading.
