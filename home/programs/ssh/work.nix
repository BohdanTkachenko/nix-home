{ pkgs, ... }:
let
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
in
{
  imports = [ ./common.nix ];

  home.packages = [
    ensureGcert
    sshWrapper
  ];

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = {
        controlMaster = "auto";
        controlPath = "~/.ssh/ctrl-%C";
        controlPersist = "yes";
        forwardAgent = true;
      };
      "*.corp.google.com" = {
        forwardAgent = true;
        identityAgent = null;
      };
      "ws" = {
        hostname = "dan.nyc.corp.google.com";
      };
    };
  };

  xdg.desktopEntries.ssh-askpass = {
    name = "ssh-askpass";
    type = "Application";
    exec = "/usr/bin/ssh-askpass";
    terminal = false;
  };

  programs.fish.interactiveShellInit = ''
    set -l gcert_check_file "/tmp/gcert_check_$USER"
    if not test -e "$gcert_check_file"; or test -n "$(find "$gcert_check_file" -mmin +60 2>/dev/null)"
      ${ensureGcert}/bin/ensure-gcert
      touch "$gcert_check_file"
    end
  '';
}
