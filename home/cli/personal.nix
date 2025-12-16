{ pkgs-unstable, ... }:
{
  home.packages = with pkgs-unstable; [
    act
    gh
    glab
    jujutsu
  ];

  imports = [
    ./common.nix
    ../programs/claude-code.nix
  ];
}
