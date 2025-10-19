#!/usr/bin/env bash
set -eu

HOME_MANAGER_ENV_FILE="$HOME/.config/home-manager.env"

LOG_FILE=/tmp/chezmoi_scripts.log
LAST_COMMAND_LOG_FILE=/tmp/chezmoi_scripts_last_command.log

COLOR_RESET='\033[0m'
COLOR_BOLD_BLUE='\033[1;34m'
COLOR_BOLD_CYAN='\033[1;36m'
COLOR_BOLD_GREEN='\033[1;32m'
COLOR_BOLD_PURPLE='\033[1;35m'
# COLOR_BOLD='\033[1m'
COLOR_BOLD_RED='\033[1;31m'
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_BLUE='\033[0;34m'
# COLOR_CYAN='\033[0;36m'

if [ -f "$HOME_MANAGER_ENV_FILE" ]; then
    source "$HOME_MANAGER_ENV_FILE"
else
    echo "❌ [ERROR] Environment file not found at '$HOME_MANAGER_ENV_FILE'. Please run the main install.sh script first." >&2
    exit 1
fi

# The env file should define this variable.
if [ -z "${HOME_MANAGER_DIR:-}" ]; then
    echo "❌ [ERROR] HOME_MANAGER_DIR is not set in '$HOME_MANAGER_ENV_FILE'. The file might be corrupt." >&2
    exit 1
fi

# A simple, unified logger.
# Usage:
#   log <type> <message>
# Example:
#   log section "Starting process..."
#   log item "Checking file..."
#   log ok "File is correct."
#   log input "Select an option:"
log() {
  local type="$1"; shift
  local text="$*"

  if [ -z "$type" ]; then
    echo "log ERROR: Missing required arguments. Usage: log <type> <text>" >&2
    return 1
  fi

  local icon=""
  local color=""
  local level=2
  local echo="echo -e"
  case $type in
    section)  icon="⚙️ "; color="${COLOR_BOLD_PURPLE}"; level=0                ;;
    item)     icon="🔷";  color="${COLOR_BOLD_CYAN}"  ; level=1                ;;
    mismatch) icon="🟡";  color="${COLOR_YELLOW}"                              ;;
    ok)       icon="🟢";  color="${COLOR_GREEN}"                               ;;
    info)     icon="ℹ️ "; color="${COLOR_BLUE}"                                ;;
    success)  icon="✅";  color="${COLOR_GREEN}"                               ;;
    error)    icon="❌";  color="${COLOR_RED}"                                 ;;
    warning)  icon="⚠️ "; color="${COLOR_YELLOW}"                              ;;
    critical) icon="‼️ "; color="${COLOR_BOLD_RED}"                            ;;
    skip)     icon="⏭️ "; color="${COLOR_YELLOW}"                              ;;
    cancel)   icon="⏹️ "; color="${COLOR_RED}"                                 ;;
    input)    icon="⌨️ "; color="${COLOR_BLUE}"  ; level=2; echo+=" -n" ;;
    *)
      echo "log ERROR: Unknown log type: '${type}'" >&2
      return 1
      ;;
  esac  

  local prefix=""
  case $level in
    0) prefix="\n${icon}" ;;
    1) prefix=" ╰─${icon}" ;;
    2) prefix="    ╰── ${icon}" ;;
  esac

  $echo "${prefix} ${color}${text}${COLOR_RESET}" | tee -a ${LOG_FILE} >&2
}

# -----------------------------------------------------------------------------
# FUNCTION: find_hosts
#
# Finds all `.nix` files in a given directory that do not start with an
# underscore (_), and prints their basenames with the .nix extension removed.
#
# @param $1 - The directory to search. Defaults to the current directory (".").
# @return   - Echos a list of hostnames, one per line.
#           - Returns exit code 1 if the directory is not found.
#
# USAGE:
#   mapfile -t hosts < <(find_hosts "./my-hosts-dir")
# -----------------------------------------------------------------------------
find_hosts() {
  local dir="${1:-.}"; shift

  if [[ ! -d "$dir" ]]; then
    log error "Directory '$dir' not found." >&2
    return 1
  fi

  (
    shopt -s nullglob
    for file_path in "$dir"/*.nix; do
      local filename
      filename=$(basename "$file_path")
      if [[ "$filename" != _* ]]; then
        echo "${filename%.nix}"
      fi
    done
  )
}

# -----------------------------------------------------------------------------
# FUNCTION: get_option_aliases
#
# Takes a list of option names and populates an associative array with
# unique single-character aliases for each option.
#
# ALGORITHM:
# 1. Tries to use the first letter of the option as the alias.
# 2. If the first letter is taken, it tries subsequent letters in the option name.
# 3. If all letters in the option name are taken, it falls back to trying all
#    numbers (0-9) and then all lowercase letters (a-z).
# 4. If no unique alias can be found, it reports an error.
#
# @param $1 - The name of the associative array to populate with results.
# @param $2... - The list of option names.
# @return   - Populates the specified array. Returns exit code 1 on error.
#
# USAGE:
#   declare -A my_aliases
#   get_option_aliases my_aliases "server" "service" "router"
# -----------------------------------------------------------------------------
get_option_aliases() {
  # Use a nameref to write to the caller's associative array
  declare -n result_map="$1"
  shift # The rest of the arguments ($@) are now the options

  # --- Pass 1: Assign first letters if available ---
  local -a conflicted_options
  for option in "$@"; do
    local first_letter="${option:0:1}"
    # Check if the alias (key) is already in the map
    if [[ -v result_map[$first_letter] ]]; then
      conflicted_options+=("$option")
    else
      result_map["$first_letter"]="$option"
    fi
  done

  # --- Pass 2: Resolve conflicts ---
  for option in "${conflicted_options[@]}"; do
    local alias_found=false

    # Strategy 2: Try the rest of the letters in the option name
    for (( i=1; i<${#option}; i++ )); do
      local letter="${option:$i:1}"
      if ! [[ -v result_map[$letter] ]]; then
        result_map["$letter"]="$option"
        alias_found=true
        break
      fi
    done

    # If an alias was found, continue to the next conflicted option
    if [[ "$alias_found" == true ]]; then
      continue
    fi

    # Strategy 3: Try all numbers, then all letters as a fallback
    for char in {0..9} {a..z}; do
      if ! [[ -v result_map[$char] ]]; then
        result_map["$char"]="$option"
        alias_found=true
        break
      fi
    done

    # If still no alias was found after all strategies, error out.
    if [[ "$alias_found" == false ]]; then
      echo "Error: Could not find a unique alias for option '$option'." >&2
      return 1
    fi
  done
}
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# FUNCTION: input_choice
#
# Prompts a user to select an option from a list, using automatically
# generated single-character aliases.
#
# @param $1 - The prompt message to display.
# @param $2 - The name of the indexed array containing the list of options.
# @return   - Echos the selected option string. Returns exit code 1 on error.
#
# USAGE:
#   options=("server" "workstation" "router")
#   selection=$(input_choice "Select a machine" options)
# -----------------------------------------------------------------------------
input_choice() {
  local prompt="$1"
  local -n options_array="$2"

  # 1. Generate the aliases for the given options
  local -A aliases
  if ! get_option_aliases aliases "${options_array[@]}"; then
    # Propagate the error message from get_option_aliases
    return 1
  fi

  # 2. Build the prompt string, e.g., "s = server | w = workstation"
  local options_str=""
  local delim=""
  # Sort keys for a consistent display order
  for key in $(printf "%s\n" "${!aliases[@]}" | sort); do
    local value="${aliases[$key]}"
    local display_text=""
    local lower_value="${value,,}"

    # Check if the alias character exists in the option string (case-insensitive)
    if [[ "$lower_value" == *"$key"* ]]; then
      # Find the prefix before the first occurrence of the key
      local prefix="${lower_value%%$key*}"
      local index="${#prefix}"

      # Reconstruct the string with the highlighted character
      local original_prefix="${value:0:$index}"
      local char_to_highlight="${value:$index:1}"
      local suffix="${value:$((index + 1))}"
      display_text="${original_prefix}${COLOR_BOLD_GREEN}${char_to_highlight}${COLOR_BOLD_BLUE}${suffix}"
    else
      # If the alias is a fallback, append it in parentheses, e.g., "reader (1)"
      display_text="${value} (${COLOR_BOLD_GREEN}${key}${COLOR_BOLD_BLUE})"
    fi

    options_str+="${delim}${display_text}"
    delim=" ${COLOR_BLUE}|${COLOR_BOLD_BLUE} "
  done

  log input "$prompt ($options_str${COLOR_BLUE}): ${COLOR_RESET}"

  # 3. Read user input until a valid choice is made
  local result=""
  while true; do
    read -rsn1 choice

    # Ignore empty input (Enter key)
    if [[ -z "$choice" ]]; then
      continue
    fi

    local lower_choice="${choice,,}"

    # Check if the chosen alias is valid
    if [[ -v "aliases[$lower_choice]" ]]; then
      result="${aliases[$lower_choice]}"
      # Echo the character to the log and to the user's screen
      echo -e "$choice" >&2
      log success "You have selected '$result'."
      break
    fi
  done

  # Return the selected option value
  echo "$result"
}
# -----------------------------------------------------------------------------

ELEVATED_WARNED=false
warn_once_elevated() {
  if [ "$ELEVATED_WARNED" = false ]; then
    log warning "This script may require elevated permissions to run."
    ELEVATED_WARNED=true
  fi
}

get_os() {
  case "$(uname -s)" in
    Linux)
      if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        if [ -n "$VARIANT_ID" ]; then
          echo "$VARIANT_ID"
        else
          echo "$ID"
        fi
      else
        echo "linux"
      fi
      ;;
    *)
      echo "other"
      ;;
  esac
}

is_os_based_on_ostree() {
  if [ -f /run/ostree-booted ]; then
    return 0
  fi

  return 1
}

is_os_supports_nix() {
  is_os_based_on_ostree
}
