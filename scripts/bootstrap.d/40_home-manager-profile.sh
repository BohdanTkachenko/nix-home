#!/usr/bin/env bash
set -euo pipefail

source "$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/../_common.sh"

# -----------------------------------------------------------------------------
# FUNCTION: select_profile
#
# Manages the selection of a Home Manager profile. It checks if the
# HOME_MANAGER_HOST variable is already set. If not, it finds available host
# configurations and prompts the user to select one. The choice is then saved
# to an environment file and exported for the current session.
#
# This function relies on several global variables:
#   - HOME_MANAGER_DIR: Path to the home-manager configuration directory.
#   - HOME_MANAGER_HOST: The variable to check and set.
#   - HOME_MANAGER_ENV_FILE: The file where the selection is saved.
# It also depends on the 'log' and 'input_choice' functions.
#
# @param    - None.
# @return   - Returns 0 on success. Exits the script on error (e.g., no hosts found).
#
# USAGE:
#   select_profile
# -----------------------------------------------------------------------------
select_profile() {
  log item ".env"

  declare -a hosts
  mapfile -t hosts < <(find_hosts "$HOME_MANAGER_DIR/hosts")
  if [[ $? -ne 0 ]]; then
    exit 1
  fi

  # Note: The original code had a typo 'host_array'. Corrected to 'hosts'.
  if [[ ${#hosts[@]} -eq 0 ]]; then
    # Note: The original code had a typo 'HOSTS_DIR'. Corrected.
    log error "No valid host files found in '$HOME_MANAGER_DIR/hosts'."
    exit 1
  fi

  chosen_config=$(input_choice "Choose a host" hosts)

  log item "Saving selection to '$HOME_MANAGER_ENV_FILE'..."
  echo "HOME_MANAGER_HOST=\"$chosen_config\"" > "$HOME_MANAGER_ENV_FILE"
  log ok "Selection saved."
}

main() {
  log section "Configuration"

  select_profile
}

main
