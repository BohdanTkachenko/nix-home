#!/usr/bin/env bash

get_os() {
  case "$(uname -s)" in
    Linux)
      if [ -f /etc/os-release ]; then
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

install_brew_apps() {
  brew "atuin"
  brew "bat"
  brew "direnv"
  brew "eza"
  brew "fd"
  brew "gh"
  brew "glab"
  brew "micro"
  brew "rg"
  brew "tealdeer"
  brew "trash-cli"
  brew "ugrep"
  brew "yq"
  brew "zoxide"
}

install_gnome_ext_from_github() {
  REPO="$1"

  echo "Installing GNOME extension ${REPO}..."

  OUT=$(mktemp --suffix=__${REPO////_}.zip)
  curl -s "https://api.github.com/repos/${REPO}/releases/latest" \
    | jq -r '.assets[] | select(.name | endswith(".zip")) | .browser_download_url' \
    | xargs curl -LJ -o "${OUT}"
  gnome-extensions install "${OUT}" --force
  rm "${OUT}"
}

install_gnome_ext() {
  UUID="$1"
  GNOME_VERSION="$2"

  echo "Installing GNOME extension '${UUID}'..."

  local ext_info=$(curl -s "https://extensions.gnome.org/extension-info/?uuid=${UUID}")
  local ext_version=$(echo "${ext_info}" \
    | jq -r ".shell_version_map | to_entries[] | select(.key == \"${GNOME_VERSION}\") | .value.pk")
  if [[ "${ext_version}" -eq "" ]]; then
    echo "Warning: Extension ${UUID} does not have a version published for GNOME ${GNOME_VERSION}. Falling back to the last available extension version."
    ext_version=$(echo "${ext_info}" \
      | jq -r '[.shell_version_map[]] | max_by(.version).pk')
  fi

  local download_url="https://extensions.gnome.org/download-extension/${UUID}.shell-extension.zip?version_tag=${ext_version}"
  local temp_file="/tmp/${UUID}.shell-extension.zip"
  if ! curl -sL "$download_url" -o "$temp_file"; then
      echo "Failed to download extension"
      return 1
  fi

  if ! gnome-extensions install --force "$temp_file" 2>/dev/null; then
      echo "Failed to install extension"
      rm -f "$temp_file"
      return 1
  fi

  # Enable extension
  if ! gnome-extensions enable "${UUID}" 2>/dev/null; then
      echo "Failed to enable extension"
      rm -f "$temp_file"
      return 1
  fi

  rm -f "$temp_file"
  echo "✓ Successfully installed and enabled ${UUID}"
  return 0  
}

install_npm_global() {
  npm install -g @google/gemini-cli
}

install_gnome_extensions() {
  local extensions=(
    "dash-to-dock@micxgx.gmail.com"
    "search-light@icedman.github.com"
  )

  local gnome_version
  gnome_version=$(gnome-shell --version | awk -F'[ .]' '{print $3}')
  echo "GNOME Shell version: $gnome_version"

  for uuid in "${extensions[@]}"; do
    install_gnome_ext "${uuid}" "${gnome_version}"
  done
}

install_flatpak_from_url() {
  URL="$1"

  echo "Installing Flatpak from ${URL} ..."
  local tmp_file=$(mktemp --suffix=.flatpak)
  curl -L -o "${tmp_file}" "${URL}"
  flatpak install --user --assumeyes --noninteractive "${tmp_file}"
  rm "${tmp_file}"
}

install_flatpak_apps() {
  install_flatpak_from_url "https://github.com/BohdanTkachenko/gearlever/releases/download/cli-update-url/it.mijorus.gearlever.flatpak"
}

install_appimage() {
  URL="$1"

  echo "Installing AppImage from ${URL} ..."
  local tmp_file=$(mktemp --suffix=.AppImage)
  curl -L -o "${tmp_file}" "${URL}"
  flatpak run it.mijorus.gearlever \
    --integrate \
    --replace \
    --yes \
    --update-url "${URL}" \
  "${tmp_file}"
}

install_appimages() {
  install_appimage "https://api.beeper.com/desktop/download/linux/x64/stable/com.automattic.beeper.desktop" 
}

configure_fish() {
  fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher"
  fish -c "fisher install IlanCosman/tide@v6"
  fish -c "tide configure --auto --style=Lean --prompt_colors='True color' --show_time='24-hour format' --lean_prompt_height='One line' --prompt_spacing=Compact --icons='Many icons' --transient=Yes"
}

configure_tldr() {
  tldr --update
  
}

install_bazzite_dx() {
  install_brew_apps

  install_npm_global
  install_gnome_extensions

  install_flatpak_apps
  install_appimages

  configure_fish
}

install() {
  case "$(get_os)" in
    bazzite-dx-gnome)
      install_bazzite_dx
      ;;
  esac
}

install
