#!/usr/bin/env bash
set -eu

REAL_HOME=$(readlink -f "$HOME")
HOME_MANAGER_DIR="$REAL_HOME/.config/nix"

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


