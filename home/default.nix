{ config, lib, ... }:
{
  imports = [
    ./common.nix
    ./hardware
    ./cli
    ./gui
    ./services/screenshot-path-clipboard.nix
    ./services/winapps.nix
    ./services/yubikey-touch-notifier.nix
  ];

  config = {
    home.username = "dan";
    home.homeDirectory = "/var/home/dan";
    sops.age.sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
  };
}
