# Common hydration configuration for personal machines
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.hydration;
  primaryUser = "dan";
  primaryHome = config.users.users.${primaryUser}.home;

  mkHydrationService = name: repoCfg: {
    name = "hydrate-${name}";
    value = {
      description = "Clone ${name} (${repoCfg.url})";
      unitConfig.ConditionPathExists = "!${repoCfg.path}";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      path = with pkgs; [
        git
        jujutsu
        coreutils
        libnotify
        openssh
      ];

      serviceConfig = {
        Type = "oneshot";
        Restart = "on-failure";
        RestartSec = "10s";
        StartLimitIntervalSec = 0;
        User = primaryUser;
        Group = "users";

        ExecStart = pkgs.writeShellScript "hydrate-${name}-logic" ''
          notify-send "Hydration: ${name}" "Cloning ${repoCfg.url}..."

          if jj git clone --colocate "${repoCfg.url}" "${repoCfg.path}"; then
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
  options.my.hydration = {
    enable = lib.mkEnableOption "hydration services for first boot";

    flakeDir = lib.mkOption {
      type = lib.types.str;
      default = "${primaryHome}/Projects/nix-home/public";
      description = ''
        Flake directory /etc/nixos points at — the one a bare `nixos-rebuild`
        (without --flake) uses. Desktops override this to the private flake.
      '';
    };

    repos = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            url = lib.mkOption {
              type = lib.types.str;
              description = "Clone URL (https for public, git@ ssh for private).";
            };
            path = lib.mkOption {
              type = lib.types.str;
              description = "Destination working-copy path.";
            };
          };
        }
      );
      default = { };
      description = ''
        Repos cloned on first boot, keyed by name. The public repo is added in
        config below; the private overlay merges in the private repo (over SSH).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # The public repo is always hydrated; the private overlay merges in the
    # private repo on desktops (these are separate attr keys, so they combine).
    my.hydration.repos.public = lib.mkDefault {
      url = "https://github.com/BohdanTkachenko/nix-home.git";
      path = "${primaryHome}/Projects/nix-home/public";
    };

    systemd.tmpfiles.rules = [
      "L+ /etc/nixos - - - - ${cfg.flakeDir}"
    ];

    systemd.services = lib.mapAttrs' mkHydrationService cfg.repos;
  };
}
