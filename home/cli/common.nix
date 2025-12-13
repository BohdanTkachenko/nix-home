{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bat
    btop
    eza
    fd
    ripgrep
    trash-cli
    ugrep
    xh
    yq
  ];

  imports = [
    ../programs/bash
    ../programs/direnv.nix
    ../programs/git
    ../programs/micro
    ../programs/starship
    ../programs/tealdeer
  ];
}
