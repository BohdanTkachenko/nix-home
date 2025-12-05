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
    ../programs/fish
    ../programs/git
    ../programs/micro
    ../programs/rust
    ../programs/shpool
    ../programs/ssh
    ../programs/starship
    ../programs/tealdeer
  ];
}
