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
    ../modules/bash
    ../modules/direnv.nix
    ../modules/fish
    ../modules/git
    ../modules/micro
    ../modules/rust
    ../modules/shpool
    ../modules/ssh
    ../modules/starship
    ../modules/tealdeer
  ];
}
