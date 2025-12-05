{ pkgs-unstable, ... }:
{
  home.packages = with pkgs-unstable; [
    act
    claude-code
    gh
    glab
    jujutsu
  ];

  imports = [
    ./common.nix
    ../programs/fish/personal.nix
    ../programs/gemini-cli
    ../programs/jujutsu
    ../programs/ssh/personal.nix
  ];
}
