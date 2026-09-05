#!/usr/bin/env bash

set -Eeuo pipefail

install_gaming_stack() {
  local -a packages=(
    gamemode
    libgamemode0:i386
    libgamemodeauto0:i386
    libgl1
    libgl1:i386
    libvulkan1
    libvulkan1:i386
    mangohud
    mesa-vulkan-drivers
    mesa-vulkan-drivers:i386
    vulkan-tools
  )

  enable_i386

  if [[ "${ENABLE_GAMESCOPE:-true}" == "true" ]]; then
    packages+=(gamescope)
  fi

  apt_install "${packages[@]}"
}
