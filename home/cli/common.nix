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
    ../programs/bash.nix
    ../programs/direnv.nix
    ../programs/fish.nix
    ../programs/git.nix
    ../programs/jujutsu.nix
    ../programs/micro.nix
    ../programs/ssh
    ../programs/starship
    ../programs/tealdeer.nix
  ];
}
