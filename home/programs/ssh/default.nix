{
  config,
  isWork,
  lib,
  pkgs,
  ...
}:
let
  # Work-specific gcert helpers
  minHours = 10;
  minSeconds = minHours * 60 * 60;
  ensureGcert = pkgs.writeShellScriptBin "ensure-gcert" ''
    if ! output=$(/usr/bin/gcertstatus --format=simple 2>&1) || \
      ! echo "$output" | ${pkgs.gawk}/bin/awk -F: '/^(loas2|corp\/normal):/ && $2 < '${toString minSeconds}' {exit 1}'; then
      echo "--- Certificate missing or expiring (<${toString minHours}h). Refreshing... ---"
      /usr/bin/gcert
    fi
  '';
  sshWrapper = pkgs.writeShellScriptBin "ssh" ''
    ${ensureGcert}/bin/ensure-gcert
    exec /usr/bin/ssh "$@"
  '';
  hasSopsKeys = !isWork && config.home.username == "dan";
in
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    # Personal: include sops secret config
    includes = lib.mkIf hasSopsKeys [
      config.sops.secrets.ssh_private_config.path
    ];

    matchBlocks = {
      # Default host config (required when enableDefaultConfig = false)
      "*" = {
        controlMaster = "auto";
        controlPath = "~/.ssh/ctrl-%C";
        controlPersist = "yes";
        forwardAgent = true;
      };
    }
    // lib.optionalAttrs isWork {
      # Work: additional ssh config
      "*.corp.google.com" = {
        forwardAgent = true;
        identityAgent = null;
      };
      "ws" = {
        hostname = "dan.nyc.corp.google.com";
      };
    };
  };

  # Personal: sops secrets
  sops.secrets.ssh_private_config = lib.mkIf hasSopsKeys {
    sopsFile = ./private-ssh-config;
    format = "binary";
  };

  # Work: gcert wrappers
  home.packages = lib.mkIf isWork [
    ensureGcert
    sshWrapper
  ];

  xdg.desktopEntries.ssh-askpass = lib.mkIf isWork {
    name = "ssh-askpass";
    type = "Application";
    exec = "/usr/bin/ssh-askpass";
    terminal = false;
  };

  programs.fish.interactiveShellInit = lib.mkIf isWork ''
    set -l gcert_check_file "/tmp/gcert_check_$USER"
    if not test -e "$gcert_check_file"; or test -n "$(find "$gcert_check_file" -mmin +60 2>/dev/null)"
      ${ensureGcert}/bin/ensure-gcert
      touch "$gcert_check_file"
    end
  '';
}
