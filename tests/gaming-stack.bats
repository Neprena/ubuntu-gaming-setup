#!/usr/bin/env bats
# shellcheck disable=SC2016

load test_helper

@test "gaming stack installs native and i386 graphics runtimes plus gaming tools" {
  make_stub dpkg '[[ "$1" == "--print-foreign-architectures" ]] && printf "i386\n"'

  run env PATH="${TEST_TMPDIR}/bin:${PATH}" DRY_RUN=1 ENABLE_GAMESCOPE=true bash -c 'source "$1/lib/common.sh"; source "$1/modules/gaming-stack.sh"; install_gaming_stack' _ "${REPO_ROOT}"

  [ "${status}" -eq 0 ]
  [[ " ${output} " == *' libgl1 '* ]]
  [[ " ${output} " == *' libgl1:i386 '* ]]
  [[ " ${output} " == *' libvulkan1 '* ]]
  [[ " ${output} " == *' libvulkan1:i386 '* ]]
  [[ " ${output} " == *' mesa-vulkan-drivers '* ]]
  [[ " ${output} " == *' mesa-vulkan-drivers:i386 '* ]]
  [[ " ${output} " == *' gamemode '* ]]
  [[ " ${output} " == *' libgamemodeauto0:i386 '* ]]
  [[ " ${output} " == *' mangohud '* ]]
  [[ " ${output} " == *' vulkan-tools '* ]]
}

@test "gaming stack enables i386 when selected independently" {
  make_stub dpkg '[[ "$1" == "--print-foreign-architectures" ]] && exit 0'

  run env PATH="${TEST_TMPDIR}/bin:${PATH}" DRY_RUN=1 ENABLE_GAMESCOPE=false bash -c 'source "$1/lib/common.sh"; source "$1/modules/gaming-stack.sh"; install_gaming_stack' _ "${REPO_ROOT}"

  [ "${status}" -eq 0 ]
  [[ "${output}" == *'[DRY-RUN] sudo dpkg --add-architecture i386'* ]]
}

@test "Gamescope is installed when enabled" {
  make_stub dpkg '[[ "$1" == "--print-foreign-architectures" ]] && printf "i386\n"'

  run env PATH="${TEST_TMPDIR}/bin:${PATH}" DRY_RUN=1 ENABLE_GAMESCOPE=true bash -c 'source "$1/lib/common.sh"; source "$1/modules/gaming-stack.sh"; install_gaming_stack' _ "${REPO_ROOT}"

  [ "${status}" -eq 0 ]
  [[ "${output}" == *'gamescope'* ]]
}

@test "Gamescope is omitted when disabled without removing the core stack" {
  make_stub dpkg '[[ "$1" == "--print-foreign-architectures" ]] && printf "i386\n"'

  run env PATH="${TEST_TMPDIR}/bin:${PATH}" DRY_RUN=1 ENABLE_GAMESCOPE=false bash -c 'source "$1/lib/common.sh"; source "$1/modules/gaming-stack.sh"; install_gaming_stack' _ "${REPO_ROOT}"

  [ "${status}" -eq 0 ]
  [[ "${output}" != *'gamescope'* ]]
  [[ "${output}" == *'gamemode'* ]]
}
