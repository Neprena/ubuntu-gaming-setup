#!/usr/bin/env bash

set -Eeuo pipefail

script_path="${BASH_SOURCE[0]}"
if [[ "${script_path}" == */* ]]; then
  script_dir="${script_path%/*}"
else
  script_dir='.'
fi
REPO_ROOT="$(cd "${script_dir}" && pwd)"
readonly REPO_ROOT

# shellcheck source=lib/common.sh
source "${REPO_ROOT}/lib/common.sh"
load_defaults "${REPO_ROOT}/config/defaults.conf"

selected_modules="${DEFAULT_MODULES}"

usage() {
  printf 'Usage: %s [--dry-run] [--modules csv]\n' "${0##*/}"
}

while (($# > 0)); do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --modules)
      if (($# < 2)) || [[ -z "$2" ]]; then
        log_error "--modules requires a comma-separated value"
        usage >&2
        exit 2
      fi
      selected_modules="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      log_error "Unknown option: $1"
      usage >&2
      exit 2
      ;;
  esac
done

IFS=',' read -r -a modules <<<"${selected_modules}"

for module in "${modules[@]}"; do
  [[ -n "${module}" ]] || die "Module names cannot be empty"

  if is_dry_run; then
    printf '[DRY-RUN] module: %s\n' "${module}"
  else
    die "Module not implemented yet: ${module}"
  fi
done
