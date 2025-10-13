{ config, pkgs, ... }:
let
  nixPkg = if config.nix.package == null then pkgs.nix else config.nix.package;
  profileDirectory = config.home.profileDirectory;
in
{
  # TODO: remove when/if https://github.com/nix-community/home-manager/pull/7949 is merged.
  xdg.configFile."systemd/user-environment-generators/05-home-manager.sh" = {
    text = ''
      #!/bin/sh

      # Displays added or modified environment variables from sourcing one or more scripts.
      # Outputs in a clean KEY=VALUE format.
      #
      # Usage:
      #   diff_env <script1.sh> [script2.sh ...]
      #
      diff_env() {
        if [[ "$#" -eq 0 ]]; then
          echo "Usage: diff_env <script1.sh> [script2.sh ...]" >&2
          return 1
        fi

        # Capture the "before" environment into a map
        declare -A before_env
        while IFS= read -r line; do
          local key="''${line%%=*}"
          local value="''${line#*=}"
          before_env["$key"]="$value"
        done < <(env)

        # Build the command to source all scripts and then print the env
        local source_command=""
        for script in "$@"; do
          if [[ ! -f "$script" ]]; then
            echo "Error: Script not found: $script" >&2
            return 1
          fi
          source_command+=". '$script'; "
        done
        source_command+="env"

        # Source scripts in a subshell and capture the "after" state
        declare -A after_env
        while IFS= read -r line; do
          local key="''${line%%=*}"
          local value="''${line#*=}"
          after_env["$key"]="$value"
        done < <(bash -c "$source_command")

        # Compare maps and print added or modified variables
        for key in "''${!after_env[@]}"; do
          # Print if the key is new OR if the value for an existing key has changed.
          if ! [[ -v before_env["$key"] ]] || [[ "''${before_env[$key]}" != "''${after_env[$key]}" ]]; then
            echo "$key=''${after_env[$key]}"
          fi
        done
      }

      diff_env \
        "${nixPkg}/etc/profile.d/nix.sh" \
        "${profileDirectory}/etc/profile.d/hm-session-vars.sh"
    '';
    executable = true;
    force = true;
  };
}
