#!/usr/bin/env bash
set -eu -o pipefail

source "$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/_common.sh"

BOOTSTRAP_D_DIR="$HOME_MANAGER_DIR/scripts/bootstrap.d"

function find_scripts() {
  local filter_env="${1-}"

  for path in $BOOTSTRAP_D_DIR/*.sh; do
    script=$(basename "$path")
    if [[ "$script" == "_"* ]]; then
      continue
    fi

    local priority=""
    local env=""
    local name=""    

    local -a parts
    IFS='_' read -r -a parts <<< "${script%.sh}"
    case "${#parts[@]}" in
        2)
            priority="${parts[0]}"
            name="${parts[1]}"
            ;;
        3)
            priority="${parts[0]}"
            env="${parts[1]}"
            name="${parts[2]}"
            ;;
        *)
            log error "Unexpected file format: '$script'. Expected: 'priority_[category_]name.sh' or _[name].sh"
            return 1
            ;;
    esac

    if [[ -z "$filter_env" || -z "$env" || "$env" == "$filter_env" ]]; then
      echo "$script|$priority|$env|$name"
    fi
  done
}

function get_environments() {
  local -n _out_environments=$1

  local -A unique_environments

  for row in $(find_scripts); do
    local -a columns
    IFS='|' read -r -a columns <<< "$row"
    env="${columns[2]}"

    if [[ ! -z "$env" ]]; then
      unique_environments["$env"]=1
    fi
  done

  _out_environments=("${!unique_environments[@]}")

  if [[ -v "_out_environments[0]" ]]; then
    for env in "${_out_environments}"; do
      log ok $env
    done
  else
    log warning "No bootstrap environments found."
  fi
}

function main() {
  log section "Bootstrap"

  log item "Environment"

  local -a environments

  get_environments environments
  environments+=("none")

  env=$(input_choice "Choose a bootstrap environment" environments)

  log item "Scripts for environment: $env"
  log warning "About to execute the following scripts"

  for row in $(find_scripts "$env"); do
    local -a columns
    IFS='|' read -r -a columns <<< "$row"
    script="${columns[0]}"

    log mismatch "$script"
  done

  local confirm_options=(confirm stop)
  confirm=$(input_choice "Please confirm" confirm_options)
  if [[ "$confirm" == "stop" ]]; then
    log cancel "Aborted"
    exit 1
  fi

  for row in $(find_scripts "$env"); do
    local -a columns
    IFS='|' read -r -a columns <<< "$row"
    script="${columns[0]}"

    "$BOOTSTRAP_D_DIR/$script"
  done
}

main
