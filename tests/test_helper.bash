REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
export REPO_ROOT

setup() {
  TEST_TMPDIR="$(mktemp -d)"
}

teardown() {
  rm -rf "${TEST_TMPDIR}"
}

make_stub() {
  local name="$1"
  local body="$2"

  mkdir -p "${TEST_TMPDIR}/bin"
  printf '#!/usr/bin/env bash\n%s\n' "${body}" >"${TEST_TMPDIR}/bin/${name}"
  chmod +x "${TEST_TMPDIR}/bin/${name}"
}
