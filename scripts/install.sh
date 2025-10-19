#!/usr/bin/env bash
set -e

GITHUB_USER="BohdanTkachenko"
REPO_NAME="dotfiles"

REAL_HOME=$(readlink -f "$HOME")
DEFAULT_DEST="$REAL_HOME/.config/home-manager"
BOOTSTRAP_SCRIPT="scripts/bootstrap.sh"
ENV_FILE="$REAL_HOME/.config/home-manager.env"

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

success() {
  printf "🚀 ${GREEN}[SUCCESS]${NC} %s\n" "$1"
}

error() {
  printf "❌ ${RED}[ERROR]${NC} %s\n" "$1" >&2
  exit 1
}
# ---

# --- Main Script ---
main() {
  if [ -f "$HOME_MANAGER_ENV_FILE" ]; then
    source "$HOME_MANAGER_ENV_FILE"
    export HOME_MANAGER_DIR
        
    if [ -z "${HOME_MANAGER_DIR:-}" ] || [ ! -d "$HOME_MANAGER_DIR" ]; then
      error "Env file points to a non-existent directory: '$HOME_MANAGER_DIR'. Please remove '$HOME_MANAGER_ENV_FILE' to start over."
    fi

    local bootstrap_script_path="$HOME_MANAGER_DIR/$BOOTSTRAP_SCRIPT"
    if [ ! -f "$bootstrap_script_path" ]; then
      error "Bootstrap script not found in '$HOME_MANAGER_DIR'. Installation may be corrupt. Please remove '$HOME_MANAGER_ENV_FILE' and run again."
    fi
        
    info "Previous installation detected at '$HOME_MANAGER_DIR'."
    info "Handing over to the bootstrap script to continue setup..."
    exec "$bootstrap_script_path"
    exit 0
  fi

  # --- First time installation ---
  info "👋 Starting Home Manager configuration setup..."

  if ! command -v git &> /dev/null; then
    error "Git is not installed. Please install Git to continue."
  fi
    
  info "First, let's decide where to store the Home Manager configuration."
  local dest_dir=""
  printf "⌨️  ${BLUE}Press ENTER to use the default location (%s), or specify a different one:${NC} " "$DEFAULT_DEST"
  read dest_dir
  dest_dir="${dest_dir:-$DEFAULT_DEST}"    
  dest_dir="${dest_dir/#\~/$REAL_HOME}"
    
  info "Configuration will be installed in: $dest_dir"

  if [ -d "$dest_dir" ]; then
    printf "⚠️  ${YELLOW}Directory '%s' already exists.${NC}\n" "$dest_dir"
        
    local bootstrap_exists=false
    if [ -f "$dest_dir/$BOOTSTRAP_SCRIPT" ]; then
      bootstrap_exists=true
    fi

    while true; do
      printf "❓ ${YELLOW}What would you like to do?${NC}\n"
      if [ "$bootstrap_exists" = true ]; then
        printf "   ${BLUE}[R]esume${NC} - Use the existing directory and run its bootstrap script.\n"
      fi
      printf "   ${BLUE}[B]ackup${NC}   - Rename the directory to *.bak.YYYYMMDD-HHMMSS and start fresh.\n"
      printf "   ${BLUE}[D]elete${NC}  - Permanently remove the directory and start fresh.\n"
      printf "   ${BLUE}[A]bort${NC}   - Exit the installer.\n"
      printf "⌨️  ${BLUE}Choose an option:${NC} "
            
      read -r -n 1 choice
      printf "\n\n"

      case "$choice" in
        [Rr])
          if [ "$bootstrap_exists" = true ]; then
            info "Resuming installation using existing directory..."
            info "Saving installation path to '$HOME_MANAGER_ENV_FILE'..."
            mkdir -p "$(dirname "$HOME_MANAGER_ENV_FILE")"
            echo "HOME_MANAGER_DIR=\"$dest_dir\"" > "$HOME_MANAGER_ENV_FILE"
            info "Handing over to the bootstrap script..."
            exec "$dest_dir/$BOOTSTRAP_SCRIPT"
            exit 0
          else
            printf "❌ ${RED}Invalid option '${choice}'. Please try again.${NC}\n\n"
          fi
        ;;
        [Bb])
          local backup_name="${dest_dir}.bak.$(date +%Y%m%d-%H%M%S)"
          info "Backing up directory to '$backup_name'..."
          mv "$dest_dir" "$backup_name"
          break
        ;;
        [Dd])
          info "Removing existing directory..."
          rm -rf "$dest_dir"
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

  info "Saving installation path to '$HOME_MANAGER_ENV_FILE'..."
  mkdir -p "$(dirname "$HOME_MANAGER_ENV_FILE")"
  echo "HOME_MANAGER_DIR=\"$dest_dir\"" > "$HOME_MANAGER_ENV_FILE"

  source "$HOME_MANAGER_ENV_FILE"
  export HOME_MANAGER_DIR

  info "Cloning repository into '$dest_dir'..."
  git clone --quiet "$HTTPS_URL" "$dest_dir"

  info "Changing remote URL to SSH..."
  (
    cd "$dest_dir"
    git remote set-url origin "$SSH_URL"
  )
  info "Remote URL changed to: $SSH_URL"

  local bootstrap_script_path="$dest_dir/$BOOTSTRAP_SCRIPT"    
  if [ ! -f "$bootstrap_script_path" ]; then
    error "Bootstrap script not found at '$bootstrap_script_path'. Cannot continue."
  fi

  info "Handing over to the bootstrap script..."
  exec "$bootstrap_script_path"
}

main
