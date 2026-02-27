#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────
# GitLab Runner Entrypoint
# Auto-registers the runner on first start and
# handles graceful shutdown with optional unregister.
# ──────────────────────────────────────────────

CONFIG_DIR="/etc/gitlab-runner"
CONFIG_FILE="${CONFIG_DIR}/config.toml"

# ── CA Certificate handling ───────────────────
setup_ca_certificate() {
  local ca_file="${CA_CERTIFICATES_PATH:-}"
  if [[ -z "$ca_file" ]]; then
    return
  fi

  if [[ ! -f "$ca_file" ]]; then
    echo "[entrypoint] WARNING: CA_CERTIFICATES_PATH set but file not found: ${ca_file}"
    return
  fi

  echo "[entrypoint] Installing custom CA certificate from ${ca_file} ..."
  cp "$ca_file" /usr/local/share/ca-certificates/custom-ca.crt
  update-ca-certificates --fresh >/dev/null 2>&1 || true
}

# ── Registration check ────────────────────────
is_registered() {
  [[ -f "$CONFIG_FILE" ]] && grep -q '\[\[runners\]\]' "$CONFIG_FILE" 2>/dev/null
}

# ── Register runner ───────────────────────────
register_runner() {
  if [[ -z "${CI_SERVER_URL:-}" ]]; then
    echo "[entrypoint] ERROR: CI_SERVER_URL is required but not set."
    exit 1
  fi
  if [[ -z "${RUNNER_TOKEN:-}" ]]; then
    echo "[entrypoint] ERROR: RUNNER_TOKEN is required but not set."
    exit 1
  fi

  local executor="${RUNNER_EXECUTOR:-docker}"

  echo "[entrypoint] Registering runner at ${CI_SERVER_URL} ..."

  local args=(
    --non-interactive
    --url "$CI_SERVER_URL"
    --token "$RUNNER_TOKEN"
    --name "${RUNNER_NAME:-unraid-runner}"
    --executor "$executor"
  )

  # Docker-executor specific options
  if [[ "$executor" == "docker" ]]; then
    args+=(--docker-image "${DOCKER_IMAGE:-alpine:latest}")

    if [[ "${DOCKER_PRIVILEGED:-false}" == "true" ]]; then
      args+=(--docker-privileged)
    fi

    local docker_volumes="${DOCKER_VOLUMES:-}"
    docker_volumes="$(echo "$docker_volumes" | xargs)"  # trim whitespace
    if [[ -n "$docker_volumes" ]]; then
      IFS=',' read -ra vols <<< "$docker_volumes"
      for vol in "${vols[@]}"; do
        vol="$(echo "$vol" | xargs)"  # trim whitespace
        [[ -n "$vol" ]] && args+=(--docker-volumes "$vol")
      done
    fi
  fi

  # Legacy token options (ignored by modern runner tokens glrt-*)
  if [[ -n "${RUNNER_TAG_LIST:-}" ]]; then
    args+=(--tag-list "$RUNNER_TAG_LIST")
  fi
  if [[ -n "${RUNNER_UNTAGGED:-}" ]]; then
    args+=(--run-untagged="$RUNNER_UNTAGGED")
  fi
  if [[ -n "${RUNNER_LOCKED:-}" ]]; then
    args+=(--locked="$RUNNER_LOCKED")
  fi

  gitlab-runner register "${args[@]}"
  echo "[entrypoint] Runner registered successfully."
}

# ── Patch global config ───────────────────────
patch_global_config() {
  local concurrent="${RUNNER_CONCURRENT:-1}"

  if [[ ! -f "$CONFIG_FILE" ]]; then
    return
  fi

  if grep -q '^concurrent' "$CONFIG_FILE"; then
    sed -i "s/^concurrent *=.*/concurrent = ${concurrent}/" "$CONFIG_FILE"
  else
    sed -i "1i concurrent = ${concurrent}" "$CONFIG_FILE"
  fi

  echo "[entrypoint] Set concurrent = ${concurrent}"
}

# ── Graceful shutdown ─────────────────────────
shutdown() {
  echo "[entrypoint] Received shutdown signal, stopping runner ..."
  gitlab-runner stop 2>/dev/null || true

  if [[ "${UNREGISTER_ON_STOP:-false}" == "true" ]]; then
    echo "[entrypoint] Unregistering runner ..."
    gitlab-runner unregister --all-runners 2>/dev/null || true
  fi

  exit 0
}

trap shutdown SIGQUIT SIGTERM SIGINT

# ── Main ──────────────────────────────────────
setup_ca_certificate

if ! is_registered; then
  register_runner
  patch_global_config
else
  echo "[entrypoint] Runner already registered, skipping registration."
  # Still patch concurrent in case the env var changed
  patch_global_config
fi

echo "[entrypoint] Starting gitlab-runner ..."
exec gitlab-runner "$@"
