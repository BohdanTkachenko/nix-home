#!/usr/bin/env bash
set -x -euo pipefail

log() {
  echo "[Flatpak Manager]: $1"
}

# --- Argument Parsing ---
# Initialize arrays
declare -A repos
declare -A desired_apps

# Default mode if not provided
ON_UNMANAGED_MODE="delete"
OVERRIDES_JSON='{}'

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    --on-unmanaged)
      ON_UNMANAGED_MODE="$2"
      shift 2
      ;;
    --repos)
      shift # past the key
      while [[ $# -gt 1 && ! "$1" =~ ^-- ]]; do
        repos["$1"]="$2"
        shift 2 # past name and location
      done
      ;;
    --packages)
      shift # past the key
      while [[ $# -gt 1 && ! "$1" =~ ^-- ]]; do
        desired_apps["$1"]="$2"
        shift 2 # past id and repo
      done
      ;;
    --overrides)
      OVERRIDES_JSON="$2"
      shift 2
      ;;
    *) # unknown option
      shift
      ;;
  esac
done
# ---

log "Searching for flatpak command..."
FLATPAK_CMD=$(command -v flatpak)
if [[ -z "$FLATPAK_CMD" ]]; then
  log "ERROR: 'flatpak' command not found in the system's PATH." >&2
  exit 1
fi
log "Found flatpak executable at: $FLATPAK_CMD"

log "Starting Flatpak sync..."

log "Ensuring Flatpak remotes exist..."
for name in "${!repos[@]}"; do
  location="${repos[$name]}"
  log "Checking remote: $name"
  "$FLATPAK_CMD" remote-add --if-not-exists "$name" "$location"
done

declare -A desired_apps
for app in "${desired_apps_array[@]}"; do
  desired_apps["$app"]=1
done

declare -A installed_apps
while read -r app; do
    if [[ -n "$app" ]]; then
        installed_apps["$app"]=1
    fi
done < <("$FLATPAK_CMD" list --app --columns=application)

log "Checking for apps to install..."
for app in "${!desired_apps[@]}"; do
  repo="${desired_apps[$app]}"
  if ! [[ -v "installed_apps[$app]" ]]; then
    log "Installing $app from remote $repo..."
    "$FLATPAK_CMD" install "$repo" --noninteractive "$app"
  fi
done

if [[ "$ON_UNMANAGED_MODE" != "ignore" ]]; then
  log "Checking for unmanaged apps (mode: $ON_UNMANAGED_MODE)..."
  for app in "${!installed_apps[@]}"; do
    if ! [[ -v "desired_apps[$app]" ]]; then
      case "$ON_UNMANAGED_MODE" in
        delete)
          log "Uninstalling unmanaged app: $app"
          "$FLATPAK_CMD" uninstall --noninteractive "$app"
          ;;
        log)
          log "Warning: Unmanaged app found: $app"
          ;;
      esac
    fi
  done
else
  log "Skipping check for unmanaged apps."
fi

log "Applying overrides..."
if ! command -v jq &> /dev/null; then
    log "ERROR: jq command could not be found, but is required for applying overrides."
    exit 1
fi

# Iterate over all desired applications to manage their overrides
for app_id in "${!desired_apps[@]}"; do
  log "Resetting existing overrides for $app_id..."
  "$FLATPAK_CMD" override --user --reset "$app_id"

  # Check if this app has overrides defined in the JSON
  if [[ $(echo "$OVERRIDES_JSON" | jq -r --arg app_id "$app_id" 'has($app_id)') == "true" ]]; then
    log "Applying overrides for $app_id"
    declare -a override_args

    keys=$(echo "$OVERRIDES_JSON" | jq -r --arg app_id "$app_id" '.[$app_id] | keys | .[]')

    for key in $keys; do
      value=$(echo "$OVERRIDES_JSON" | jq -r --arg app_id "$app_id" --arg key "$key" '.[$app_id][$key]')
      value_type=$(echo "$OVERRIDES_JSON" | jq -r --arg app_id "$app_id" --arg key "$key" '.[$app_id][$key] | type')

      if [[ "$value_type" == "array" ]]; then
        while IFS= read -r item; do
          item_expanded="${item/#\~/$HOME}"
          override_args+=("--$key=$item_expanded")
        done < <(echo "$value" | jq -r '.[]')
      else
        value_expanded="${value/#\~/$HOME}"
        override_args+=("--$key=$value_expanded")
      fi
    done

    if [[ ${#override_args[@]} -gt 0 ]]; then
      "$FLATPAK_CMD" override --user "$app_id" "${override_args[@]}"
    fi
  fi
done

log "Cleaning up unused Flatpak runtimes..."
"$FLATPAK_CMD" uninstall --unused --noninteractive

log "Flatpak management complete."