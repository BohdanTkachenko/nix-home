{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bat
    btop
    eza
    fd
    procs
    ripgrep
    trash-cli
    ugrep
    xh
    yq
  ];

  imports = [
    ../programs/bash.nix
    ../programs/direnv.nix
    ../programs/dotfiles.nix
    ../programs/fish.nix
    ../programs/ai/ask.nix
    ../programs/ai/gemini-cli.nix
    ../programs/git.nix
    ../programs/jujutsu.nix
    ../programs/micro.nix
    ../programs/ssh
    ../programs/starship
    ../programs/tealdeer.nix
  ];
}
