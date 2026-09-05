#!/usr/bin/env bats

load test_helper

@test "enable_i386 does nothing when i386 is already enabled" {
  make_stub dpkg '[[ "$1" == "--print-foreign-architectures" ]] && printf "i386\n"'

  run env PATH="${TEST_TMPDIR}/bin:${PATH}" DRY_RUN=1 bash -c 'source "$1/lib/common.sh"; source "$1/modules/system.sh"; enable_i386' _ "${REPO_ROOT}"

  [ "${status}" -eq 0 ]
  [[ "${output}" != *'--add-architecture'* ]]
}

@test "enable_i386 adds i386 once when it is absent" {
  make_stub dpkg '[[ "$1" == "--print-foreign-architectures" ]] && exit 0'

  run env PATH="${TEST_TMPDIR}/bin:${PATH}" DRY_RUN=1 bash -c 'source "$1/lib/common.sh"; source "$1/modules/system.sh"; enable_i386' _ "${REPO_ROOT}"

  [ "${status}" -eq 0 ]
  [ "${output}" = '[DRY-RUN] sudo dpkg --add-architecture i386' ]
}
