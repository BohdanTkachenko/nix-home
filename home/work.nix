{ ... }:
{
  custom.profile = "work";

  home.username = "bohdant";
  home.homeDirectory = "/usr/local/google/home/bohdant";

  imports = [
    ./cli/work.nix
    ./gui/work.nix
  ];
}
