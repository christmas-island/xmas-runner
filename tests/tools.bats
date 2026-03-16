#!/usr/bin/env bats

# =============================================================================
# Verify all pre-installed tools in the xmas-runner image
# =============================================================================

# --- Tier 1: Core ---

@test "git is installed" {
  run git --version
  [ "$status" -eq 0 ]
}

@test "curl is installed" {
  run curl --version
  [ "$status" -eq 0 ]
}

@test "jq is installed" {
  run jq --version
  [ "$status" -eq 0 ]
}

@test "wget is installed" {
  run wget --version
  [ "$status" -eq 0 ]
}

@test "zip is installed" {
  run zip --version
  [ "$status" -eq 0 ]
}

@test "unzip is installed" {
  run unzip -v
  [ "$status" -eq 0 ]
}

@test "sudo is installed" {
  run sudo --version
  [ "$status" -eq 0 ]
}

# --- Tier 2: Language runtimes ---

@test "go is installed" {
  run go version
  [ "$status" -eq 0 ]
  [[ "$output" == *"go1.24"* ]]
}

@test "node is installed (v22)" {
  run node --version
  [ "$status" -eq 0 ]
  [[ "$output" == v22.* ]]
}

@test "npm is installed" {
  run npm --version
  [ "$status" -eq 0 ]
}

@test "python3 is installed" {
  run python3 --version
  [ "$status" -eq 0 ]
}

@test "pip is installed" {
  run pip3 --version
  [ "$status" -eq 0 ]
}

@test "rustc is installed" {
  run rustc --version
  [ "$status" -eq 0 ]
}

@test "cargo is installed" {
  run cargo --version
  [ "$status" -eq 0 ]
}

@test "rustup is installed" {
  run rustup --version
  [ "$status" -eq 0 ]
}

# --- Tier 3: Build & lint tools ---

@test "docker CLI is installed" {
  run docker --version
  [ "$status" -eq 0 ]
}

@test "docker buildx is installed" {
  run docker buildx version
  [ "$status" -eq 0 ]
}

@test "goreleaser is installed" {
  run goreleaser --version
  [ "$status" -eq 0 ]
}

@test "prek is installed" {
  run prek --version
  [ "$status" -eq 0 ]
}

@test "hadolint is installed" {
  run hadolint --version
  [ "$status" -eq 0 ]
}

@test "shellcheck is installed" {
  run shellcheck --version
  [ "$status" -eq 0 ]
}

@test "shfmt is installed" {
  run shfmt --version
  [ "$status" -eq 0 ]
}

@test "golangci-lint is installed" {
  run golangci-lint --version
  [ "$status" -eq 0 ]
}

@test "bats is installed" {
  run bats --version
  [ "$status" -eq 0 ]
}

@test "tofu (OpenTofu) is installed" {
  run tofu --version
  [ "$status" -eq 0 ]
}

@test "tflint is installed" {
  run tflint --version
  [ "$status" -eq 0 ]
}

@test "terraform-docs is installed" {
  run terraform-docs --version
  [ "$status" -eq 0 ]
}

# --- Tier 4: Extras ---

@test "psql is installed" {
  run psql --version
  [ "$status" -eq 0 ]
}

@test "pg_isready is installed" {
  run pg_isready --version
  [ "$status" -eq 0 ]
}

@test "mysql client is installed" {
  run mysql --version
  [ "$status" -eq 0 ]
}

@test "yarn is installed" {
  run yarn --version
  [ "$status" -eq 0 ]
}

# --- Runner agent ---

@test "GitHub Actions runner is installed" {
  [ -f /home/runner/actions-runner/run.sh ]
}

@test "GitHub Actions runner config exists" {
  [ -f /home/runner/actions-runner/config.sh ]
}

# --- User setup ---

@test "runner user exists" {
  run id runner
  [ "$status" -eq 0 ]
}

@test "runner user has sudo" {
  run sudo -n true
  [ "$status" -eq 0 ]
}
