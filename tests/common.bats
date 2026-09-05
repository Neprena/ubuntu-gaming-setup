#!/usr/bin/env bats

load test_helper

@test "dry-run renders a privileged command without executing it" {
  run bash -c 'source "$1/lib/common.sh"; DRY_RUN=1; run_privileged apt-get install -y steam' _ "${REPO_ROOT}"

  [ "${status}" -eq 0 ]
  [ "${output}" = '[DRY-RUN] sudo apt-get install -y steam' ]
}

@test "invoking_user prefers the desktop user recorded by sudo" {
  run env SUDO_USER=player USER=root bash -c 'source "$1/lib/common.sh"; invoking_user' _ "${REPO_ROOT}"

  [ "${status}" -eq 0 ]
  [ "${output}" = 'player' ]
}

@test "load_defaults loads values from an explicit configuration file" {
  cat >"${TEST_TMPDIR}/defaults.conf" <<'EOF'
ENABLE_GAMESCOPE=false
DEFAULT_MODULES=system,steam
EOF

  run bash -c 'source "$1/lib/common.sh"; load_defaults "$2"; printf "%s|%s\n" "$ENABLE_GAMESCOPE" "$DEFAULT_MODULES"' _ "${REPO_ROOT}" "${TEST_TMPDIR}/defaults.conf"

  [ "${status}" -eq 0 ]
  [ "${output}" = 'false|system,steam' ]
}
