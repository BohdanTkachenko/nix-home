#!/usr/bin/env bash
set -eu

REAL_HOME=$(readlink -f "$HOME")
HOME_MANAGER_DIR="$REAL_HOME/.config/home-manager"
HOME_MANAGER_ENV_FILE="$HOME_MANAGER_DIR/.env"

LOG_FILE=/tmp/nix-home_scripts.log
LAST_COMMAND_LOG_FILE=/tmp/nix-home_scripts_last_command.log

COLOR_RESET='\033[0m'
COLOR_BOLD_BLUE='\033[1;34m'
COLOR_BOLD_CYAN='\033[1;36m'
COLOR_BOLD_GREEN='\033[1;32m'
COLOR_BOLD_PURPLE='\033[1;35m'
COLOR_BOLD='\033[1m'
COLOR_BOLD_RED='\033[1;31m'
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_BLUE='\033[0;34m'
COLOR_CYAN='\033[0;36m'

if [ -f "$HOME_MANAGER_ENV_FILE" ]; then
  source "$HOME_MANAGER_ENV_FILE"
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
  local type="$1"
  shift
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
  section)
    icon="⚙️ "
    color="${COLOR_BOLD_PURPLE}"
    level=0
    ;;
  item)
    icon="🔷"
    color="${COLOR_BOLD_CYAN}"
    level=1
    ;;
  mismatch)
    icon="🟡"
    color="${COLOR_YELLOW}"
    ;;
  ok)
    icon="🟢"
    color="${COLOR_GREEN}"
    ;;
  info)
    icon="ℹ️ "
    color="${COLOR_BLUE}"
    ;;
  success)
    icon="✅"
    color="${COLOR_GREEN}"
    ;;
  error)
    icon="❌"
    color="${COLOR_RED}"
    ;;
  warning)
    icon="⚠️ "
    color="${COLOR_YELLOW}"
    ;;
  critical)
    icon="‼️ "
    color="${COLOR_BOLD_RED}"
    ;;
  skip)
    icon="⏭️ "
    color="${COLOR_YELLOW}"
    ;;
  cancel)
    icon="⏹️ "
    color="${COLOR_RED}"
    ;;
  input)
    icon="⌨️ "
    color="${COLOR_BLUE}"
    level=2
    echo+=" -n"
    ;;
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
  local dir="${1:-.}"

  if [[ ! -d "$dir" ]]; then
    log error "Directory '$dir' not found." >&2
    return 1
  fi

  (
    shopt -s nullglob
    for file_path in "$dir"/*.nix; do
      local filename
      filename=$(basename "$file_path")
      echo "${filename%.nix}"
    done
  )
}

confirm() {
  log input "Do you want to continue? [Y/n] "
  read -n 1 response
  echo

  response=${response:-Y}
  if [[ ! $response =~ ^[Yy]$ ]]; then
    log cancel "Aborted"
    return 1
  fi

  return 0
}

ELEVATED_WARNED=false
warn_once_elevated() {
  if [ "$ELEVATED_WARNED" = false ]; then
    log warning "This script may require elevated permissions to run."
    ELEVATED_WARNED=true
  fi
}

ask_before_reboot() {
  local msg_reboot_required="A reboot is needed for changes to take effect."
  local msg_reboot_rerun="Please run this script again after the reboot."

  log critical "$msg_reboot_required $msg_reboot_rerun"

  if ! confirm; then
    exit 10
  fi

  systemctl reboot --now
}

copy_file() {
  local src="$1"
  local dst="$2"
  local sudo="$3"

  if [ -z "$sudo" ]; then
    mkdir -p "$(dirname "$dst")"
    cp "${src}" "${dst}"
    return 0
  fi

  warn_once_elevated
  sudo mkdir -p "$(dirname "$dst")"
  sudo cp "${src}" "${dst}"
}

ask_file_diff() {
  local dst="$1"
  local diff="$2"

  while true; do
    PS3="File exists, but its contents differ for $dst"
    local options=(accept dff skip abort)
    select option in "${options[@]}"; do
      case $option in
      "accept")
        return 0
        ;;
      "diff")
        echo "${diff}" | less -R
        continue
        ;;
      "skip")
        return 1
        ;;
      "abort")
        exit 1
        ;;
      *)
        echo "Invalid option $REPLY"
        continue
        ;;
      esac
    done
  done
}

maybe_copy_file() {
  local src="$1"
  local dst="$2"
  local sudo="$3"

  log item $dst

  if ! test -f "${dst}"; then
    log mismatch "Does not exist. Creating..."
    copy_file "${src}" "${dst}" "${sudo}"
    log success "Created."
    return 11
  fi

  if ! diff=$(git diff --color --no-index -- "${dst}" "${src}"); then
    log mismatch "Content differs. Asking user for confirmation..."
    if ask_file_diff "${dst}" "${diff}"; then
      log info "User confirmed. Replacing..."
      copy_file "${src}" "${dst}" "${sudo}"
      log success "Replaced."
      return 12
    fi

    log skip "User declined. Skipping."
    return 10
  fi

  log ok "Already correct."
  return 0
}
