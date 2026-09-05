#!/usr/bin/env bash

set -Eeuo pipefail

install_nvidia_driver() {
  local secure_boot

  apt_install ubuntu-drivers-common
  run_privileged ubuntu-drivers install

  secure_boot="$(secure_boot_state)"
  if [[ "${secure_boot}" == "enabled" ]]; then
    log_warn "Secure Boot is enabled; complete any MOK enrollment prompt during reboot"
  elif [[ "${secure_boot}" == "unknown" ]]; then
    log_warn "Secure Boot state is unknown; check MOK enrollment requirements before reboot"
  fi

  log_warn "A reboot may be required before the NVIDIA driver is active"
}
