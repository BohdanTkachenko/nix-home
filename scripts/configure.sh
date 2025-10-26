#!/usr/bin/env bash
set -eu -o pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)/_common.sh"

main() {
  log section "Configuring Environment"

  log item "Select Host"

  mapfile -t host_options < <(find_hosts "$HOME_MANAGER_DIR/hosts")

  PS3="Choose a host: "
  select host in "${host_options[@]}"; do
    case $host in
    *)
      if [[ -z "$host" ]]; then
        echo "Invalid option $REPLY"
        continue
      fi
      log mismatch "Selected host: $host"
      break
      ;;
    esac
  done

  if [[ -z "$host" ]]; then
    log error "No host selected. Aborting."
    exit 1
  fi

  env=""
  if [[ "$host" == "work"* ]]; then
    env="debian"
  elif [[ "$host" == "personal"* ]]; then
    env="rpm-ostree"
  else
    log warning "Could not infer environment for host '$host'. You may need to set HOME_MANAGER_ENV manually."
  fi

  if [[ -n "$env" ]]; then
    log mismatch "Inferred environment: $env"
  fi

  {
    echo "HOME_MANAGER_ENV=\"$env\""
    echo "HOME_MANAGER_HOST=\"$host\""
  } >"$HOME_MANAGER_ENV_FILE"

  log success "Configuration saved successfully to $HOME_MANAGER_ENV_FILE"
}

main
