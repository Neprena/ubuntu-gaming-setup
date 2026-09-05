#!/usr/bin/env bats
# shellcheck disable=SC2016

load test_helper

write_os_release() {
  printf 'ID=ubuntu\nVERSION_ID="%s"\n' "$1" >"${TEST_TMPDIR}/os-release"
}

@test "detect_ubuntu_version reads Ubuntu 26.04 from os-release" {
  write_os_release '26.04'

  run env OS_RELEASE_FILE="${TEST_TMPDIR}/os-release" bash -c 'source "$1/lib/common.sh"; detect_ubuntu_version' _ "${REPO_ROOT}"

  [ "${status}" -eq 0 ]
  [ "${output}" = '26.04' ]
}

@test "detect_arch normalizes Ubuntu amd64 to x86_64" {
  make_stub dpkg '[[ "$1" == "--print-architecture" ]] && printf "amd64\n"'

  run env PATH="${TEST_TMPDIR}/bin:${PATH}" bash -c 'source "$1/lib/common.sh"; detect_arch' _ "${REPO_ROOT}"

  [ "${status}" -eq 0 ]
  [ "${output}" = 'x86_64' ]
}

@test "detect_desktop recognizes GNOME case-insensitively" {
  run env XDG_CURRENT_DESKTOP='ubuntu:GNOME' bash -c 'source "$1/lib/common.sh"; detect_desktop' _ "${REPO_ROOT}"

  [ "${status}" -eq 0 ]
  [ "${output}" = 'gnome' ]
}

@test "preflight accepts Ubuntu 26.04 GNOME on Wayland" {
  write_os_release '26.04'
  make_stub dpkg '[[ "$1" == "--print-architecture" ]] && printf "amd64\n"'

  run env PATH="${TEST_TMPDIR}/bin:${PATH}" OS_RELEASE_FILE="${TEST_TMPDIR}/os-release" XDG_CURRENT_DESKTOP=GNOME XDG_SESSION_TYPE=wayland bash -c 'source "$1/lib/common.sh"; preflight_check' _ "${REPO_ROOT}"

  [ "${status}" -eq 0 ]
}

@test "preflight warns for a TTY when GNOME is installed" {
  write_os_release '26.04'
  make_stub dpkg '[[ "$1" == "--print-architecture" ]] && printf "amd64\n"'

  run env -u XDG_SESSION_TYPE -u DISPLAY -u WAYLAND_DISPLAY PATH="${TEST_TMPDIR}/bin:${PATH}" OS_RELEASE_FILE="${TEST_TMPDIR}/os-release" XDG_CURRENT_DESKTOP=GNOME bash -c 'source "$1/lib/common.sh"; preflight_check' _ "${REPO_ROOT}"

  [ "${status}" -eq 0 ]
  [[ "${output}" == *'[WARN]'*'TTY'* ]]
}

@test "preflight rejects an active non-Wayland graphical session" {
  write_os_release '26.04'
  make_stub dpkg '[[ "$1" == "--print-architecture" ]] && printf "amd64\n"'

  run env PATH="${TEST_TMPDIR}/bin:${PATH}" OS_RELEASE_FILE="${TEST_TMPDIR}/os-release" XDG_CURRENT_DESKTOP=GNOME XDG_SESSION_TYPE=x11 DISPLAY=:0 bash -c 'source "$1/lib/common.sh"; preflight_check' _ "${REPO_ROOT}"

  [ "${status}" -ne 0 ]
  [[ "${output}" == *'Wayland'* ]]
}

@test "preflight rejects an unsupported Ubuntu release" {
  write_os_release '24.04'
  make_stub dpkg '[[ "$1" == "--print-architecture" ]] && printf "amd64\n"'

  run env PATH="${TEST_TMPDIR}/bin:${PATH}" OS_RELEASE_FILE="${TEST_TMPDIR}/os-release" XDG_CURRENT_DESKTOP=GNOME XDG_SESSION_TYPE=wayland bash -c 'source "$1/lib/common.sh"; preflight_check' _ "${REPO_ROOT}"

  [ "${status}" -ne 0 ]
  [[ "${output}" == *'Ubuntu 26.04'* ]]
}

@test "preflight reports enabled Secure Boot" {
  write_os_release '26.04'
  make_stub dpkg '[[ "$1" == "--print-architecture" ]] && printf "amd64\n"'
  make_stub mokutil '[[ "$1" == "--sb-state" ]] && printf "SecureBoot enabled\n"'

  run env PATH="${TEST_TMPDIR}/bin:${PATH}" OS_RELEASE_FILE="${TEST_TMPDIR}/os-release" XDG_CURRENT_DESKTOP=GNOME XDG_SESSION_TYPE=wayland bash -c 'source "$1/lib/common.sh"; preflight_check' _ "${REPO_ROOT}"

  [ "${status}" -eq 0 ]
  [[ "${output}" == *'[INFO] Secure Boot: enabled'* ]]
}

@test "preflight warns when Secure Boot state cannot be determined" {
  write_os_release '26.04'
  make_stub dpkg '[[ "$1" == "--print-architecture" ]] && printf "amd64\n"'
  make_stub mokutil 'exit 1'

  run env PATH="${TEST_TMPDIR}/bin:${PATH}" OS_RELEASE_FILE="${TEST_TMPDIR}/os-release" XDG_CURRENT_DESKTOP=GNOME XDG_SESSION_TYPE=wayland bash -c 'source "$1/lib/common.sh"; preflight_check' _ "${REPO_ROOT}"

  [ "${status}" -eq 0 ]
  [[ "${output}" == *'[WARN] Secure Boot state: unknown'* ]]
}
