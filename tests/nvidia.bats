#!/usr/bin/env bats
# shellcheck disable=SC2016

load test_helper

@test "NVIDIA installation delegates driver selection to ubuntu-drivers" {
  run env DRY_RUN=1 bash -c 'source "$1/lib/common.sh"; source "$1/modules/nvidia.sh"; install_nvidia_driver' _ "${REPO_ROOT}"

  [ "${status}" -eq 0 ]
  [[ "${output}" == *'[DRY-RUN] sudo apt-get install -y -- ubuntu-drivers-common'* ]]
  [[ "${output}" == *'[DRY-RUN] sudo ubuntu-drivers install'* ]]
}

@test "NVIDIA installation never pins a driver branch or invokes a run installer" {
  run env DRY_RUN=1 bash -c 'source "$1/lib/common.sh"; source "$1/modules/nvidia.sh"; install_nvidia_driver' _ "${REPO_ROOT}"

  [ "${status}" -eq 0 ]
  [[ "${output}" != *'nvidia-driver-'* ]]
  [[ "${output}" != *'.run'* ]]
}

@test "a first NVIDIA installation requests an installer stop for reboot" {
  run env DRY_RUN=1 bash -c 'source "$1/lib/common.sh"; source "$1/modules/nvidia.sh"; install_nvidia_driver; printf "stop=%s\n" "$NVIDIA_REBOOT_REQUIRED"' _ "${REPO_ROOT}"

  [ "${status}" -eq 0 ]
  [[ "${output}" == *'stop=1'* ]]
}
