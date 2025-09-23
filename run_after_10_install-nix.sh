#!/usr/bin/env bash
set -eu

source common.sh

OSTREE_PREPARE_ROOT_CONFIG_FILE=/etc/ostree/prepare-root.conf
CHEZMOI_OSTREE_PREPARE_ROOT_CONFIG_FILE=./prepare-root.conf

ELEVATED_WARNED=false
warn_once_elevated() {
  if [ "$ELEVATED_WARNED" = false ]; then
    log warning "This script may require elevated permissions to run."
    ELEVATED_WARNED=true
  fi
}

warn_reboot() {
  local msg_reboot_required="A reboot will be performed for ostree changes to take effect."
  local msg_reboot_rerun="Please run this script again after the reboot."

  log critical "$msg_reboot_required $msg_reboot_rerun"

  if ! whiptail \
    --yesno "$msg_reboot_required\n\n$msg_reboot_rerun" \
    10 50 \
    3>&1 1>&2 2>&3;
  then
    log cancel "User declined reboot. Exiting."
    exit 10
  fi
}

copy_file_sudo() {
  local src="$1"; shift
  local dst="$1"; shift

  warn_once_elevated
  sudo cp "${src}" "${dst}"
}

ask_file_diff() {
  local dst="$1"; shift
  local diff="$1"; shift

  local choice=$(whiptail \
    --title "$dst" \
    --menu "\nFile exists, but its contents differ. Choose an action:" \
    15 60 3 \
    "Accept" "Proceed with the current operation." \
    "Diff"   "Show the difference between two files." \
    "Skip"   "Ignore this item and move to the next." \
    3>&1 1>&2 2>&3 || true
  )

  if [ "$choice" == "Skip" ]; then
    return 1
  fi

  if [ "$choice" == "Diff" ]; then
    echo "${diff}" | less -R
    ask_file_diff "${dst}" "${diff}"
    return $?
  fi

  if [ "$choice" == "Accept" ]; then
    return 0
  fi

  log cancel "User selected Cancel. Exiting."
  exit 10
}

maybe_copy_file_sudo() {
  local src="$1"; shift
  local dst="$1"; shift

  log item $dst

  if ! test -f "${dst}"; then
    log mismatch "Does not exist. Creating..."
    copy_file_sudo "${src}" "${dst}"
    log success "Created."
    return 11
  fi

  if ! diff=$(git diff --color --no-index -- "${dst}" "${src}"); then
    log mismatch "Content differs. Asking user for confirmation..."
    if ask_file_diff "${dst}" "${diff}"; then
      log info "User confirmed. Replacing..."
      copy_file_sudo "${src}" "${dst}"
      log success "Replaced."
      return 12
    fi

    log skip "User declined. Skipping."
    return 10
  fi

  log ok "Already correct."
  return 0
}

update_initramfs_etc_sudo() {
  warn_reboot
  warn_once_elevated
  sudo rpm-ostree initramfs-etc --reboot --force-sync --track=$OSTREE_PREPARE_ROOT_CONFIG_FILE
}

configure_ostree() {
  log section "Configuring ostree..."

  local file_changed=0
  maybe_copy_file_sudo \
    "$CHEZMOI_OSTREE_PREPARE_ROOT_CONFIG_FILE" \
    "$OSTREE_PREPARE_ROOT_CONFIG_FILE" \
  || file_changed=$?

  log item "InitramfsEtc"
  if [ $file_changed -gt 10 ]; then
    log mismatch "$OSTREE_PREPARE_ROOT_CONFIG_FILE has changed, running rpm-ostree initramfs-etc..."
    update_initramfs_etc_sudo
    return 10
  else
    log ok "$OSTREE_PREPARE_ROOT_CONFIG_FILE is correct."
  fi

  local ostree_status=$(rpm-ostree status --json | jq -r --arg file "$OSTREE_PREPARE_ROOT_CONFIG_FILE" '
    def has_config(d):
      (d | ."initramfs-etc"?) | arrays | any(. == $file);

    if has_config((.deployments[] | select(.booted == true))) then
      "BOOTED"
    elif has_config((.deployments[] | select(.staged == true))) then
      "STAGED"
    else
      "NONE"
    end
  ')
  case "$ostree_status" in
    STAGED)
      log mismatch "Staged ostree deployment is already configured correctly."
      warn_reboot
      systemctl reboot --now
      return 11
      ;;
    NONE)
      log mismatch "Neither currently booted nor staged ostree deployment is configured correctly. Running rpm-ostree initramfs-etc..."
      update_initramfs_etc_sudo
      return 12
      ;;
  esac

  log ok "Currently booted ostree deployment is already configured correctly."
  return 0
}

install_nix() {
  log section "Installing Nix..."

  log item "Nix"

  if [ -d "/nix" ]; then
    log ok "Nix is already installed."
  else
    log mismatch "Not installed. Installing using Determinate Systems installer..."
    {
      curl -fsSL https://install.determinate.systems/nix 2> >(tee -a "$LOG_FILE") | \
        sh -s -- install --no-confirm
    } 2>&1 | tee -a "$LOG_FILE"
    exit_codes=("${PIPESTATUS[@]}")

    if ! ([ "${exit_codes[0]}" -eq 0 ] && [ "${exit_codes[1]}" -eq 0 ]); then
      log error "Nix installation failed. Check '$LOG_FILE' for details."
      return 1
    fi

    log success "Nix installation completed successfully."
  fi
}

update_home_manager() {
  log item "Home Manager"

  local home_manager_command
  if command -v home-manager &> /dev/null; then
    home_manager_command=(home-manager switch)
    log ok "Home-Manager is already installed."
    log mismatch "Rebuilding home configuration..."
  else
    home_manager_command=(nix run home-manager -- switch)
    log mismatch "Installing Home-Manager and building home configuration..."
  fi

  if "${home_manager_command[@]}" &>> "$LOG_FILE"; then
    log success "Installed Home Manager and built home configuration."
  else
    log error "Failed to install Home Manager and build home configuration."
    return 1
  fi

  source /nix/var/nix/profiles/default/etc/profile.d/nix.sh

  return 0
}

install_bazzite_dx() {
  configure_ostree
  install_nix
  update_home_manager
}

install() {
  case "$(get_os)" in
    bazzite-dx-gnome|bazzite-dx-nvidia-gnome)
      install_bazzite_dx
      ;;
  esac
}

install
