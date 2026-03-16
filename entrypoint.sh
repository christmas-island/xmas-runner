#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# xmas-runner entrypoint
# Registers the GitHub Actions runner, starts it, and handles graceful shutdown.
# =============================================================================

RUNNER_DIR="/home/runner/actions-runner"
GITHUB_URL="${GITHUB_URL:-https://github.com}"
RUNNER_NAME="${RUNNER_NAME:-$(hostname)}"
RUNNER_LABELS="${RUNNER_LABELS:-self-hosted,linux,x64,xmas-runner}"
RUNNER_GROUP="${RUNNER_GROUP:-default}"
RUNNER_WORKDIR="${RUNNER_WORKDIR:-_work}"
EPHEMERAL="${EPHEMERAL:-true}"

# ---------------------------------------------------------------------------
# Obtain registration token
# ---------------------------------------------------------------------------
get_registration_token() {
    if [[ -n "${RUNNER_TOKEN:-}" ]]; then
        echo "${RUNNER_TOKEN}"
        return
    fi

    if [[ -z "${GITHUB_PAT:-}" ]]; then
        echo "ERROR: Either RUNNER_TOKEN or GITHUB_PAT must be set" >&2
        exit 1
    fi

    if [[ -z "${RUNNER_SCOPE:-}" || -z "${RUNNER_TARGET:-}" ]]; then
        echo "ERROR: GITHUB_PAT requires RUNNER_SCOPE (repo|org) and RUNNER_TARGET" >&2
        exit 1
    fi

    local api_url
    case "${RUNNER_SCOPE}" in
        repo)
            api_url="${GITHUB_URL}/api/v3/repos/${RUNNER_TARGET}/actions/runners/registration-token"
            # Handle github.com vs GHE API URL
            if [[ "${GITHUB_URL}" == "https://github.com" ]]; then
                api_url="https://api.github.com/repos/${RUNNER_TARGET}/actions/runners/registration-token"
            fi
            ;;
        org)
            api_url="${GITHUB_URL}/api/v3/orgs/${RUNNER_TARGET}/actions/runners/registration-token"
            if [[ "${GITHUB_URL}" == "https://github.com" ]]; then
                api_url="https://api.github.com/orgs/${RUNNER_TARGET}/actions/runners/registration-token"
            fi
            ;;
        *)
            echo "ERROR: RUNNER_SCOPE must be 'repo' or 'org', got '${RUNNER_SCOPE}'" >&2
            exit 1
            ;;
    esac

    local token
    token=$(curl -s -X POST \
        -H "Authorization: Bearer ${GITHUB_PAT}" \
        -H "Accept: application/vnd.github+json" \
        "${api_url}" | jq -r '.token')

    if [[ "${token}" == "null" || -z "${token}" ]]; then
        echo "ERROR: Failed to obtain registration token from ${api_url}" >&2
        exit 1
    fi

    echo "${token}"
}

# ---------------------------------------------------------------------------
# Deregister runner on shutdown
# ---------------------------------------------------------------------------
cleanup() {
    echo "Caught signal — removing runner..."
    local token
    token=$(get_registration_token)
    "${RUNNER_DIR}/config.sh" remove --token "${token}" || true
    exit 0
}

trap cleanup SIGTERM SIGINT

# ---------------------------------------------------------------------------
# Configure the runner
# ---------------------------------------------------------------------------
REG_TOKEN=$(get_registration_token)

# Determine the registration URL
if [[ "${RUNNER_SCOPE:-}" == "org" ]]; then
    REG_URL="${GITHUB_URL}/${RUNNER_TARGET}"
elif [[ "${RUNNER_SCOPE:-}" == "repo" ]]; then
    REG_URL="${GITHUB_URL}/${RUNNER_TARGET}"
elif [[ -n "${RUNNER_TARGET:-}" ]]; then
    REG_URL="${GITHUB_URL}/${RUNNER_TARGET}"
else
    echo "ERROR: RUNNER_TARGET must be set (org name or owner/repo)" >&2
    exit 1
fi

CONFIG_ARGS=(
    --url "${REG_URL}"
    --token "${REG_TOKEN}"
    --name "${RUNNER_NAME}"
    --labels "${RUNNER_LABELS}"
    --runnergroup "${RUNNER_GROUP}"
    --work "${RUNNER_WORKDIR}"
    --unattended
    --replace
    --disableupdate
)

if [[ "${EPHEMERAL}" == "true" ]]; then
    CONFIG_ARGS+=(--ephemeral)
fi

echo "Configuring runner '${RUNNER_NAME}' for ${REG_URL}..."
"${RUNNER_DIR}/config.sh" "${CONFIG_ARGS[@]}"

# ---------------------------------------------------------------------------
# Start the runner
# ---------------------------------------------------------------------------
echo "Starting runner..."
exec "${RUNNER_DIR}/run.sh" &
RUNNER_PID=$!
wait ${RUNNER_PID}
