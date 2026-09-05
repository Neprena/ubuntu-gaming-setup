#!/usr/bin/env bats

load test_helper

@test "setup rejects an unknown option" {
  run "${REPO_ROOT}/setup.sh" --not-a-real-option

  [ "${status}" -eq 2 ]
  [[ "${output}" == *'Unknown option: --not-a-real-option'* ]]
}

@test "setup parses a comma-separated module list in order" {
  run "${REPO_ROOT}/setup.sh" --dry-run --modules system,steam

  [ "${status}" -eq 0 ]
  [[ "${output}" == *'[DRY-RUN] module: system'* ]]
  [[ "${output}" == *'[DRY-RUN] module: steam'* ]]
  [[ "${output}" != *'[DRY-RUN] module: nvidia'* ]]
}
