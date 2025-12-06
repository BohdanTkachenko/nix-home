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
    ../programs/claude-code
    ../programs/fish/personal.nix
    ../programs/gemini-cli
    ../programs/jujutsu
    ../programs/ssh/personal.nix
  ];
}
