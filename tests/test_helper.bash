REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
export REPO_ROOT

setup() {
  TEST_TMPDIR="$(mktemp -d)"
}

teardown() {
  rm -rf "${TEST_TMPDIR}"
}
