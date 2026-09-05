#!/usr/bin/env bash

set -Eeuo pipefail

enable_i386() {
  local foreign_architectures

  foreign_architectures="$(dpkg --print-foreign-architectures)"
  if grep -Fxq 'i386' <<<"${foreign_architectures}"; then
    return 0
  fi

  run_privileged dpkg --add-architecture i386
}

install_system_foundation() {
  enable_i386
  run_privileged apt-get update
  apt_install ca-certificates curl flatpak jq mokutil pciutils software-properties-common
}
