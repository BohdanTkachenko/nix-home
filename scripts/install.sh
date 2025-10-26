#!/usr/bin/env bash
set -eu -o pipefail

GITHUB_USER="BohdanTkachenko"
REPO_NAME="nix-home"

REAL_HOME=$(readlink -f "$HOME")
HOME_MANAGER_DIR="$REAL_HOME/.config/home-manager"

HTTPS_URL="https://github.com/$GITHUB_USER/$REPO_NAME.git"
SSH_URL="git@github.com:$GITHUB_USER/$REPO_NAME.git"

# --- Colors ---
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color
# ---

# --- Helper Functions ---
info() {
  printf "⚙️  ${BLUE}[INFO]${NC} %s\n" "$1"
}

warn() {
  printf "⚠️  ${YELLOW}[WARN]${NC} %s\n" "$1"
}

error() {
  printf "❌ ${RED}[ERROR]${NC} %s\n" "$1" >&2
  exit 1
}

bootstrap() {
  info "Handing over to 'make bootstrap'..."
  (cd "$HOME_MANAGER_DIR" && make bootstrap)

  exit 0
}
# ---

# --- Main Script ---
main() {
  info "👋 Starting Home Manager configuration setup..."

  if ! command -v git &>/dev/null; then
    error "Git is not installed. Please install Git to continue."
  fi

  if [ -d "$HOME_MANAGER_DIR" ]; then
    warn "Home Manager directory '$HOME_MANAGER_DIR' already exists."

    while true; do
      printf "❓ ${YELLOW}What would you like to do?${NC}\n"
      printf "   ${BLUE}[R]esume${NC} - Use the existing directory and run 'make bootstrap'.\n"
      printf "   ${BLUE}[B]ackup${NC} - Rename the directory to *.bak.YYYYMMDD-HHMMSS and start fresh.\n"
      printf "   ${BLUE}[D]elete${NC} - Permanently remove the directory and start fresh.\n"
      printf "   ${BLUE}[A]bort${NC}  - Exit the installer.\n"
      printf "⌨️  ${BLUE}Choose an option:${NC} "

      read -r -n 1 choice
      printf "\n\n"

      case "$choice" in
      [Rr])
        bootstrap
        ;;
      [Bb])
        local backup_name="${HOME_MANAGER_DIR}.bak.$(date +%Y%m%d-%H%M%S)"
        info "Backing up directory to '$backup_name'..."
        cd "$REAL_HOME"
        mv "$HOME_MANAGER_DIR" "$backup_name"
        break
        ;;
      [Dd])
        info "Removing existing directory..."
        cd "$REAL_HOME"
        rm -rf "$HOME_MANAGER_DIR"
        break
        ;;
      [Aa])
        info "Aborting installation."
        exit 0
        ;;
      *)
        printf "❌ ${RED}Invalid option '${choice}'. Please try again.${NC}\n\n"
        ;;
      esac
    done
  fi

  info "Cloning repository into '$HOME_MANAGER_DIR'..."
  git clone --quiet "$HTTPS_URL" "$HOME_MANAGER_DIR"
  cd "$HOME_MANAGER_DIR"

  info "Changing remote URL to SSH..."
  git remote set-url origin "$SSH_URL"
  info "Remote URL changed to: $SSH_URL"

  bootstrap
}

main
