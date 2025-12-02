#!/usr/bin/env bash
set -eu -o pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)/_common.sh"

BOOTSTRAP_D_DIR="$HOME_MANAGER_DIR/scripts/bootstrap.d"

function find_scripts() {
  for path in $BOOTSTRAP_D_DIR/*.sh; do
    script=$(basename "$path")
    if [[ "$script" == "_"* ]]; then
      continue
    fi

    local priority=""
    local name=""

    local -a parts
    IFS='_' read -r -a parts <<<"${script%.sh}"
    case "${#parts[@]}" in
    2)
      priority="${parts[0]}"
      name="${parts[1]}"
      ;;
    *)
      log error "Unexpected file format: '$script'. Expected: 'priority_name.sh' or _[name].sh"
      return 1
      ;;
    esac

    echo "$script|$priority|$name"
  done
}

function main() {
  log section "Bootstrap"

  log warning "About to execute the following scripts"

  for row in $(find_scripts); do
    local -a columns
    IFS='|' read -r -a columns <<<"$row"
    script="${columns[0]}"

    log mismatch "$script"
  done

  if ! confirm; then
    exit 1
  fi

  for row in $(find_scripts); do
    local -a columns
    IFS='|' read -r -a columns <<<"$row"
    script="${columns[0]}"

    "$BOOTSTRAP_D_DIR/$script"
  done
}

main
