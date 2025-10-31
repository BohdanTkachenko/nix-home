{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bat
    eza
    fd
    ripgrep
    trash-cli
    ugrep
    yq
  ];

  imports = [
    ../modules/bash
    ../modules/fish
    ../modules/git
    ../modules/micro
    ../modules/rust
    ../modules/shpool
    ../modules/ssh
    ../modules/tealdeer
  ];
}
