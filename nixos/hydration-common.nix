# Common hydration configuration for personal machines
{
  config,
  lib,
  pkgs,
  ...
}:

let
  primaryUser = builtins.head (builtins.attrNames config.my.users);
  primaryHome = config.users.users.${primaryUser}.home;

  mkHydrationService =
    {
      name,
      repo,
      path,
      description,
    }:
    {
      name = "hydrate-${name}";
      value = {
        description = description;
        unitConfig.ConditionPathExists = "!${path}";
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];

        path = with pkgs; [
          git
          jujutsu
          coreutils
          libnotify
        ];

        serviceConfig = {
          Type = "oneshot";
          Restart = "on-failure";
          RestartSec = "10s";
          StartLimitIntervalSec = 0;
          User = primaryUser;
          Group = "users";

          ExecStart = pkgs.writeShellScript "hydrate-${name}-logic" ''
            notify-send "Hydration: ${name}" "Cloning ${repo}..."

            if jj git clone --colocate "${repo}" "${path}"; then
               notify-send "Hydration: ${name}" "Success!"
               exit 0
            else
               notify-send -u critical "Hydration: ${name}" "Failed. Retrying..."
               exit 1
            fi
          '';
        };
      };
    };
in
{
  systemd.tmpfiles.rules = [
    "L+ /etc/nixos - - - - ${primaryHome}/.config/nix"
  ];

  systemd.services = lib.listToAttrs [
    (mkHydrationService {
      name = "nixos-config";
      description = "Clone NixOS Config";
      repo = "https://github.com/BohdanTkachenko/nix-home.git";
      path = "${primaryHome}/.config/nix";
    })
  ];
}