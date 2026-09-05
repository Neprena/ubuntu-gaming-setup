#!/usr/bin/env bash
# NVIDIA_REBOOT_REQUIRED is consumed by setup.sh after this module returns.
# shellcheck disable=SC2034

set -Eeuo pipefail

install_nvidia_driver() {
  local secure_boot
  local driver_was_active=0

  NVIDIA_REBOOT_REQUIRED=0
  if command_exists nvidia-smi && nvidia-smi -L >/dev/null 2>&1; then
    driver_was_active=1
  fi

  apt_install ubuntu-drivers-common
  run_privileged ubuntu-drivers install

  if ((driver_was_active == 0)); then
    NVIDIA_REBOOT_REQUIRED=1
  fi

  secure_boot="$(secure_boot_state)"
  if [[ "${secure_boot}" == "enabled" ]]; then
    log_warn "Secure Boot is enabled; complete any MOK enrollment prompt during reboot"
  elif [[ "${secure_boot}" == "unknown" ]]; then
    log_warn "Secure Boot state is unknown; check MOK enrollment requirements before reboot"
  fi

  log_warn "A reboot may be required before the NVIDIA driver is active"
}
