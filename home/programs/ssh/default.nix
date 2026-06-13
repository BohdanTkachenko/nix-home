{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my;
in
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    # Personal: include sops secret config
    includes = lib.mkIf cfg.secrets.sops.enable [
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
    # On the lemonade server host (the local PC), reverse-tunnel its lemonade
    # server onto the headless workbench so workbench's `lemonade open`/`copy`
    # reach this machine's browser and clipboard. Keyed on the `wb` alias; its
    # `HostName` lives in the sops-encrypted ssh config included above.
    // lib.optionalAttrs cfg.lemonade.server.enable {
      "wb" = {
        remoteForwards = [
          {
            bind = {
              address = "127.0.0.1";
              port = 2489;
            };
            host = {
              address = "127.0.0.1";
              port = 2489;
            };
          }
        ];
      };
    };
  };

  # Personal: sops secrets
  sops.secrets.ssh_private_config = lib.mkIf cfg.secrets.sops.enable {
    sopsFile = ./private-ssh-config;
    format = "binary";
  };
}
