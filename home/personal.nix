{ config, ... }:
{
  home.username = "dan";
  home.homeDirectory = "/var/home/dan";

  my.secrets.sops.enable = true;
  sops.age.sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];

  imports = [
    ./cli/personal.nix
    ./gui/personal.nix
  ];
}
