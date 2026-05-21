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
    };
  };

  # Personal: sops secrets
  sops.secrets.ssh_private_config = lib.mkIf cfg.secrets.sops.enable {
    sopsFile = ./private-ssh-config;
    format = "binary";
  };
}
