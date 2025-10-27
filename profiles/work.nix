{ ... }:
{
  home.username = "bohdant";
  home.homeDirectory = "/home/bohdant";

  imports = [
    ./cli-work.nix
    ./gui-work.nix
  ];
}
