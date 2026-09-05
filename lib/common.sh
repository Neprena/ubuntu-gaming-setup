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

detect_ubuntu_version() {
  local os_release_file="${OS_RELEASE_FILE:-/etc/os-release}"
  local id=''
  local version_id=''

  [[ -r "${os_release_file}" ]] || die "Cannot read ${os_release_file}"

  while IFS='=' read -r key value; do
    value="${value%\"}"
    value="${value#\"}"
    case "${key}" in
      ID) id="${value}" ;;
      VERSION_ID) version_id="${value}" ;;
    esac
  done <"${os_release_file}"

  [[ "${id}" == "ubuntu" ]] || die "Unsupported operating system: ${id:-unknown}"
  printf '%s\n' "${version_id}"
}

detect_arch() {
  local deb_arch

  deb_arch="$(dpkg --print-architecture)"
  case "${deb_arch}" in
    amd64) printf 'x86_64\n' ;;
    *) printf '%s\n' "${deb_arch}" ;;
  esac
}

detect_desktop() {
  local desktop="${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-}}"

  if [[ "${desktop,,}" == *gnome* ]]; then
    printf 'gnome\n'
    return 0
  fi

  if command_exists gnome-shell; then
    printf 'gnome\n'
    return 0
  fi

  printf 'unknown\n'
  return 1
}

detect_session_type() {
  if [[ -n "${XDG_SESSION_TYPE:-}" ]]; then
    printf '%s\n' "${XDG_SESSION_TYPE,,}"
  elif [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
    printf 'wayland\n'
  elif [[ -n "${DISPLAY:-}" ]]; then
    printf 'x11\n'
  else
    printf 'tty\n'
  fi
}

secure_boot_state() {
  local output

  if ! command_exists mokutil; then
    printf 'unknown\n'
    return 0
  fi

  output="$(mokutil --sb-state 2>/dev/null || true)"
  case "${output,,}" in
    *enabled*) printf 'enabled\n' ;;
    *disabled*) printf 'disabled\n' ;;
    *) printf 'unknown\n' ;;
  esac
}

preflight_check() {
  local version arch desktop session

  version="$(detect_ubuntu_version)"
  [[ "${version}" == "26.04" ]] || die "Ubuntu 26.04 is required; found ${version:-unknown}"

  arch="$(detect_arch)"
  [[ "${arch}" == "x86_64" ]] || die "x86_64 is required; found ${arch:-unknown}"

  desktop="$(detect_desktop)" || die "GNOME is required"
  [[ "${desktop}" == "gnome" ]] || die "GNOME is required"

  session="$(detect_session_type)"
  case "${session}" in
    wayland) ;;
    tty) log_warn "TTY detected; GNOME Wayland will be required for graphical use" ;;
    *) die "Wayland is required for an active graphical session; found ${session}" ;;
  esac

  log_info "Preflight passed for Ubuntu ${version} on ${arch}, GNOME ${session}"
}
