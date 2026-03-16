# =============================================================================
# xmas-runner: Purpose-built GitHub Actions self-hosted runner
# For the christmas-island GitHub org
# Base: ubuntu:24.04 | Multi-arch: amd64 + arm64
# =============================================================================
FROM ubuntu:24.04

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# ---------------------------------------------------------------------------
# Build arguments — version pins (easy to update)
# ---------------------------------------------------------------------------
ARG TARGETARCH
ARG RUNNER_VERSION=2.322.0
ARG GO_VERSION=1.24.1
ARG NODE_MAJOR=22
ARG GORELEASER_VERSION=2.8.2
ARG GOLANGCI_LINT_VERSION=1.63.4
ARG HADOLINT_VERSION=2.12.0
ARG SHFMT_VERSION=3.10.0
ARG OPENTOFU_VERSION=1.9.0
ARG TFLINT_VERSION=0.55.1
ARG TERRAFORM_DOCS_VERSION=0.19.0
ARG PREK_VERSION=4.1.0
ARG BATS_VERSION=1.11.1
ARG SHELLCHECK_VERSION=0.10.0

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# ---------------------------------------------------------------------------
# Tier 1 — Core tools (every repo uses these)
# ---------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    jq \
    bash \
    ca-certificates \
    wget \
    zip \
    unzip \
    sudo \
    gnupg \
    lsb-release \
    software-properties-common \
    apt-transport-https \
    build-essential \
    pkg-config \
    libssl-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# Tier 2 — Language runtimes
# ---------------------------------------------------------------------------

# --- Go (official tarball) ---
RUN GOARCH=${TARGETARCH} \
    && curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${GOARCH}.tar.gz" \
       | tar -C /usr/local -xz
ENV PATH="/usr/local/go/bin:/root/go/bin:${PATH}"
ENV GOPATH="/root/go"

# --- Node.js 22 LTS (NodeSource) ---
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/* \
    && npm install -g yarn



# --- Python 3.12 + pip ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/* \
    && ln -sf /usr/bin/python3 /usr/bin/python

# --- Rust (via rustup — supports both arches natively) ---
ENV RUSTUP_HOME="/usr/local/rustup"
ENV CARGO_HOME="/usr/local/cargo"
ENV PATH="/usr/local/cargo/bin:${PATH}"
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
    | sh -s -- -y --default-toolchain stable --profile minimal \
    && rustup component add clippy rustfmt \
    && chmod -R a+rw ${RUSTUP_HOME} ${CARGO_HOME}

# ---------------------------------------------------------------------------
# Tier 3 — Build & lint tools
# ---------------------------------------------------------------------------

# --- Docker CLI + Buildx plugin (NO daemon — we mount the host socket) ---
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
       | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && chmod a+r /etc/apt/keyrings/docker.gpg \
    && echo "deb [arch=${TARGETARCH} signed-by=/etc/apt/keyrings/docker.gpg] \
       https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
       > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
       docker-ce-cli \
       docker-buildx-plugin \
    && rm -rf /var/lib/apt/lists/*

# --- QEMU user-static (cross-platform builds) ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    qemu-user-static \
    binfmt-support \
    && rm -rf /var/lib/apt/lists/*

# --- goreleaser ---
RUN GOARCH=${TARGETARCH} \
    && if [ "${GOARCH}" = "amd64" ]; then GRARCH="x86_64"; else GRARCH="arm64"; fi \
    && curl -fsSL "https://github.com/goreleaser/goreleaser/releases/download/v${GORELEASER_VERSION}/goreleaser_Linux_${GRARCH}.tar.gz" \
       | tar -C /usr/local/bin -xz goreleaser

# --- prek (pre-commit-rs) ---
RUN GOARCH=${TARGETARCH} \
    && if [ "${GOARCH}" = "amd64" ]; then PREKARCH="x86_64"; else PREKARCH="aarch64"; fi \
    && curl -fsSL "https://github.com/j178/pre-commit-rs/releases/download/v${PREK_VERSION}/pre-commit-rs-v${PREK_VERSION}-${PREKARCH}-unknown-linux-musl.tar.gz" \
       | tar -C /usr/local/bin -xz prek

# --- hadolint ---
RUN GOARCH=${TARGETARCH} \
    && if [ "${GOARCH}" = "amd64" ]; then HLARCH="x86_64"; else HLARCH="arm64"; fi \
    && curl -fsSL -o /usr/local/bin/hadolint \
       "https://github.com/hadolint/hadolint/releases/download/v${HADOLINT_VERSION}/hadolint-Linux-${HLARCH}" \
    && chmod +x /usr/local/bin/hadolint

# --- shellcheck ---
RUN GOARCH=${TARGETARCH} \
    && if [ "${GOARCH}" = "amd64" ]; then SCARCH="x86_64"; else SCARCH="aarch64"; fi \
    && curl -fsSL "https://github.com/koalaman/ShellCheck/releases/download/v${SHELLCHECK_VERSION}/shellcheck-v${SHELLCHECK_VERSION}.linux.${SCARCH}.tar.xz" \
       | tar -C /usr/local/bin --strip-components=1 -xJ "shellcheck-v${SHELLCHECK_VERSION}/shellcheck"

# --- shfmt ---
RUN GOARCH=${TARGETARCH} \
    && curl -fsSL -o /usr/local/bin/shfmt \
       "https://github.com/mvdan/sh/releases/download/v${SHFMT_VERSION}/shfmt_v${SHFMT_VERSION}_linux_${GOARCH}" \
    && chmod +x /usr/local/bin/shfmt

# --- golangci-lint ---
RUN GOARCH=${TARGETARCH} \
    && curl -fsSL "https://github.com/golangci/golangci-lint/releases/download/v${GOLANGCI_LINT_VERSION}/golangci-lint-${GOLANGCI_LINT_VERSION}-linux-${GOARCH}.tar.gz" \
       | tar -C /usr/local/bin --strip-components=1 -xz "golangci-lint-${GOLANGCI_LINT_VERSION}-linux-${GOARCH}/golangci-lint"

# --- bats-core ---
RUN curl -fsSL "https://github.com/bats-core/bats-core/archive/refs/tags/v${BATS_VERSION}.tar.gz" \
       | tar -xz \
    && cd "bats-core-${BATS_VERSION}" \
    && ./install.sh /usr/local \
    && cd .. && rm -rf "bats-core-${BATS_VERSION}"

# --- OpenTofu ---
RUN GOARCH=${TARGETARCH} \
    && curl -fsSL "https://github.com/opentofu/opentofu/releases/download/v${OPENTOFU_VERSION}/tofu_${OPENTOFU_VERSION}_linux_${GOARCH}.tar.gz" \
       | tar -C /usr/local/bin -xz tofu

# --- tflint ---
RUN GOARCH=${TARGETARCH} \
    && curl -fsSL "https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_${GOARCH}.zip" \
       -o /tmp/tflint.zip \
    && unzip -o /tmp/tflint.zip -d /usr/local/bin \
    && rm /tmp/tflint.zip

# --- terraform-docs ---
RUN GOARCH=${TARGETARCH} \
    && curl -fsSL "https://github.com/terraform-docs/terraform-docs/releases/download/v${TERRAFORM_DOCS_VERSION}/terraform-docs-v${TERRAFORM_DOCS_VERSION}-linux-${GOARCH}.tar.gz" \
       | tar -C /usr/local/bin -xz terraform-docs

# ---------------------------------------------------------------------------
# Tier 4 — Extras
# ---------------------------------------------------------------------------

# --- PostgreSQL client (pg_isready, psql) + MySQL client ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-client \
    mysql-client \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# GitHub Actions Runner agent
# ---------------------------------------------------------------------------
RUN ARCH=${TARGETARCH} \
    && if [ "${ARCH}" = "amd64" ]; then RUNNERARCH="x64"; elif [ "${ARCH}" = "arm64" ]; then RUNNERARCH="arm64"; fi \
    && mkdir -p /home/runner/actions-runner \
    && curl -fsSL "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${RUNNERARCH}-${RUNNER_VERSION}.tar.gz" \
       | tar -C /home/runner/actions-runner -xz

# ---------------------------------------------------------------------------
# Create non-root 'runner' user
# ---------------------------------------------------------------------------
RUN useradd -m -d /home/runner -s /bin/bash runner \
    && echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && chown -R runner:runner /home/runner \
    && chmod -R a+rw ${RUSTUP_HOME} ${CARGO_HOME}

# Add runner user to docker group (will be created if socket is mounted)
RUN groupadd -f docker && usermod -aG docker runner

# Install runner dependencies
RUN /home/runner/actions-runner/bin/installdependencies.sh

# ---------------------------------------------------------------------------
# Entrypoint
# ---------------------------------------------------------------------------
COPY entrypoint.sh /home/runner/entrypoint.sh
RUN chmod +x /home/runner/entrypoint.sh

# Copy tests into image for CI verification
COPY tests/ /home/runner/actions-runner/tests/

# Set Go path for runner user
ENV GOPATH="/home/runner/go"
ENV PATH="/home/runner/go/bin:/usr/local/go/bin:/usr/local/cargo/bin:${PATH}"

USER runner
WORKDIR /home/runner/actions-runner

ENTRYPOINT ["/home/runner/entrypoint.sh"]
