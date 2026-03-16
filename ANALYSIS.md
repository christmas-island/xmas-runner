# Christmas Island CI Tooling Audit

## Repos With CI (20 active)

### Language Runtimes Required
| Runtime | Repos | Setup Action |
|---------|-------|-------------|
| **Go** | hive-server, hive-local, finagle, go-scaffold, 700-days, only-claws-api, wish-api, keyquest | `actions/setup-go` |
| **Node.js** | hive-plugin, 700-days (svelte), cr-semantic-release, all release workflows (semantic-release) | `actions/setup-node` |
| **Python** | dns, hive-server, hive-local, finagle, go-scaffold, k8s (pre-commit) | `actions/setup-python` |
| **Rust** | clawpass, common-repo, contextium | `dtolnay/rust-toolchain` |
| **OpenTofu/Terraform** | tf-modules-github, dns | `opentofu/setup-opentofu` |

### Build Tools Required
| Tool | Repos |
|------|-------|
| **Docker (build+push)** | crablet, actuate, email-handler, finagle, go-scaffold, hive-server, hive-local, only-claws-api, ssiui, sticker-shop |
| **Docker Buildx + QEMU** | crablet (multi-arch) |
| **goreleaser** | finagle, go-scaffold, hive-server, hive-local |
| **semantic-release (npx)** | finagle, go-scaffold, hive-server, hive-local, cr-semantic-release, tf-modules-github, crablet, hive-plugin |
| **pre-commit / prek** | crablet, finagle, go-scaffold, hive-server, hive-local, k8s, dns |
| **bats** | crablet |
| **cargo (build/test/clippy/fmt)** | clawpass, common-repo, contextium |

### CI Service Containers
| Service | Repos |
|---------|-------|
| **Postgres** | 700-days (nightly migrations) |
| **MySQL** | keyquest |
| **CockroachDB** | hive-server (testcontainers, self-managed in test) |

### Linting Tools
| Tool | Repos |
|------|-------|
| **golangci-lint** | wish-api |
| **staticcheck** | only-claws-api |
| **hadolint** | crablet |
| **shellcheck** | (in crablet Dockerfile, prek hooks) |
| **tflint** | tf-modules-github |
| **trivy** | tf-modules-github |
| **terraform-docs** | tf-modules-github |
| **commitlint** | common-repo, cr-semantic-release, tf-modules-github |
| **ruff** | (in prek hooks for python) |
| **shfmt** | (in prek hooks) |

### Special Runners
| Runner | Repos |
|--------|-------|
| **macOS (Xcode)** | 700-days (ios-tests, self-hosted-mac) |
| **self-hosted** | 700-days (test-mac-runner), crablet (attempted) |

## Summary: What the runner image needs

### Tier 1 — Core (every repo uses these)
- git, curl, jq, bash, ca-certificates
- Docker daemon + CLI + Buildx + QEMU (cross-platform builds)
- Node.js 22 + npm (semantic-release in every release workflow)

### Tier 2 — Language runtimes (most repos)
- Go (latest stable) — 8 repos
- Python 3.12 — 6 repos (pre-commit, dns scripts)
- Rust toolchain (stable) — 3 repos

### Tier 3 — Build/lint tools
- goreleaser
- prek (pre-commit-rs)
- hadolint, shellcheck, shfmt
- golangci-lint, staticcheck
- tflint, terraform-docs, trivy
- OpenTofu
- bats-core

### Tier 4 — Extras
- pip (for pre-commit, diff-cover, dns requirements)
- yarn (700-days svelte)
- cargo-llvm-cov, cargo-nextest (common-repo)
- pg_isready, psql (700-days migrations)
- mysql client (keyquest)

### NOT needed (from GH full runner)
- Java, .NET, Ruby, PHP, Swift, Kotlin, Julia, Fortran
- Android SDK, Xcode tools
- Azure CLI, AWS CLI, Google Cloud CLI
- Browsers (Chrome, Firefox, Edge)
- Selenium, Chromium
- Miniconda, Homebrew
- All the Azure/cloud tooling
- Most of the 50GB of stuff

## Recommendation

The GitHub full runner image (~50GB) is massive overkill. ~80% of it is unused.

A purpose-built image with Tiers 1-3 would cover all repos and be ~2-3GB.
Tier 4 items can be installed on-demand in workflows (they already are via setup-* actions).

The key insight: most language runtimes are installed via `actions/setup-*` which downloads
and caches them anyway. The runner just needs: a working Ubuntu base, Docker, and Node.js.
Everything else gets installed by the workflow steps themselves.
