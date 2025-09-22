#!/usr/bin/env bash
set -eu

LOG_FILE=/tmp/chezmoi_scripts.log

COLOR_RESET='\033[0m'
COLOR_BOLD_PURPLE='\033[1;35m'
COLOR_BOLD_CYAN='\033[1;36m'
# COLOR_BOLD='\033[1m'
COLOR_BOLD_RED='\033[1;31m'
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_BLUE='\033[0;34m'
# COLOR_CYAN='\033[0;36m'

# A simple, unified logger.
# Usage:
#   log <type> <message>
# Example:
#   log section "Starting process..."
#   log item "Checking file..."
#   log ok "File is correct."
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
  case $type in
    section)  icon="⚙️ "; color="${COLOR_BOLD_PURPLE}"; level=0 ;;
    item)     icon="🔷";  color="${COLOR_BOLD_CYAN}"; level=1 ;;
    mismatch) icon="🟡";  color="${COLOR_YELLOW}" ;;
    ok)       icon="🟢";  color="${COLOR_GREEN}" ;;
    info)     icon="ℹ️ "; color="${COLOR_BLUE}" ;;
    success)  icon="✅";  color="${COLOR_GREEN}" ;;
    error)    icon="❌";  color="${COLOR_RED}" ;;
    warning)  icon="⚠️ "; color="${COLOR_YELLOW}" ;;
    critical) icon="‼️ "; color="${COLOR_BOLD_RED}" ;;
    skip)     icon="⏭️ ";  color="${COLOR_YELLOW}" ;;
    cancel)   icon="⏹️ "; color="${COLOR_RED}" ;;
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

  echo -e "${prefix} ${color}${text}${COLOR_RESET}" | tee -a /dev/stderr >> $LOG_FILE
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