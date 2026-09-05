#!/usr/bin/env bash

set -Eeuo pipefail

install_system_foundation() {
  enable_i386
  run_privileged apt-get update
  apt_install ca-certificates curl flatpak jq mokutil pciutils software-properties-common
}
