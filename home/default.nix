{ config, lib, ... }:
{
  imports = [
    ./common.nix
    ./hardware
    ./cli
    ./gui
    ./services/winapps.nix
    ./services/yubikey-touch-notifier.nix
  ];

  config = lib.mkMerge [
    (lib.mkIf (config.my.environment == "personal") {
      home.username = "dan";
      home.homeDirectory = "/var/home/dan";

      my.secrets.sops.enable = true;
      sops.age.sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
    })
    (lib.mkIf (config.my.environment == "work") {
      home.username = "bohdant";

      my.google.enable = true;
      my.identity.email = "bohdant@google.com";

      nixpkgs.config.allowUnfree = true;
      services.xremap.enable = false;
    })
  ];
}
