#!/usr/bin/env bash

set -Eeuo pipefail

DRY_RUN="${DRY_RUN:-0}"

log_info() {
  printf '[INFO] %s\n' "$*"
}

log_warn() {
  printf '[WARN] %s\n' "$*" >&2
}

log_error() {
  printf '[ERROR] %s\n' "$*" >&2
}

die() {
  log_error "$*"
  exit 1
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

is_dry_run() {
  [[ "${DRY_RUN}" == "1" ]]
}

run_privileged() {
  if is_dry_run; then
    printf '[DRY-RUN] sudo'
    printf ' %q' "$@"
    printf '\n'
    return 0
  fi

  sudo -- "$@"
}

apt_install() {
  run_privileged apt-get install -y -- "$@"
}

invoking_user() {
  if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
    printf '%s\n' "${SUDO_USER}"
  else
    printf '%s\n' "${USER:-$(id -un)}"
  fi
}

load_defaults() {
  local defaults_file="${1:-}"

  [[ -n "${defaults_file}" ]] || die "A defaults file is required"
  [[ -r "${defaults_file}" ]] || die "Cannot read defaults: ${defaults_file}"

  # shellcheck disable=SC1090
  source "${defaults_file}"
}
