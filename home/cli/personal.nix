{ pkgs-unstable, ... }:
{
  home.packages = with pkgs-unstable; [
    act
    gh
    glab
  ];

  imports = [
    ./common.nix
    ../programs/claude-code.nix
  ];
}
