{ ... }:
{
  home.username = "bohdant";

  imports = [
    ./cli/work.nix
    ./gui/work.nix
  ];
}
