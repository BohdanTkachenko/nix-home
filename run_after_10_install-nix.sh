#!/usr/bin/env bash
set -eu

source $CHEZMOI_SOURCE_DIR/common.sh

OSTREE_PREPARE_ROOT_CONFIG_FILE=/etc/ostree/prepare-root.conf
CHEZMOI_OSTREE_PREPARE_ROOT_CONFIG_FILE=./prepare-root.conf

warn_reboot() {
  local msg_reboot_required="A reboot will be performed for ostree changes to take effect."
  local msg_reboot_rerun="Please run this script again after the reboot."

  log critical "$msg_reboot_required $msg_reboot_rerun"

  read -p "Do you want to reboot now? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
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

  while true; do
    echo "File exists, but its contents differ for $dst"
    echo "Choose an action:"
    echo "  1. Accept - Proceed with the current operation."
    echo "  2. Diff   - Show the difference between two files."
    echo "  3. Skip   - Ignore this item and move to the next."
    read -p "Enter your choice (1-3): " choice

    case "$choice" in
      1)
        return 0
        ;;
      2)
        echo "${diff}" | less -R
        continue
        ;;
      3)
        return 1
        ;;
      *)
        echo "Invalid choice. Please try again."
        ;;
    esac
  done
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

  log item "OS Check"
  log info "Detected OS: $(get_os)"
  if is_os_based_on_ostree; then
    log ok "OS is based on OSTree."
  else
    log skip "OS is not based on OSTree. Skipping ostree configuration."
    return 0
  fi

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
      ((d | ."initramfs-etc"?) // []) | any(. == $file);

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

  log item "OS Check"
  log info "Detected OS: $(get_os)"
  if is_os_supports_nix; then
    log ok "OS supports Nix."
  else
    log skip "OS does not support Nix. Skipping Nix installation."
    return 0
  fi

  log item "Nix"

  if [ -f "/nix/receipt.json" ]; then
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

install() {
  configure_ostree
  install_nix
}

install
