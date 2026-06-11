{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bat
    btop
    eza
    fd
    nushell
    procs
    ripgrep
    sox
    trash-cli
    ugrep
    xh
    yq
  ];

  imports = [
    ../programs/bash.nix
    ../programs/cargo.nix
    ../programs/containers.nix
    ../programs/direnv.nix
    ../programs/dotfiles.nix
    ../programs/fish.nix
    ../programs/ai/ask.nix
    ../programs/ai/gemini-cli.nix
    ../programs/audio-fix.nix
    ../programs/git.nix
    ../programs/jujutsu.nix
    ../programs/jj-workspace.nix
    ../programs/micro.nix
    ../programs/ssh
    ../programs/starship
    ../programs/tealdeer.nix
  ];
}
