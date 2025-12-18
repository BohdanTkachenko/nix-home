{ config, ... }:
{
  home.username = "dan";
  home.homeDirectory = "/var/home/dan";
  sops.age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";

  imports = [
    ./cli/personal.nix
    ./gui/personal.nix
  ];
}
