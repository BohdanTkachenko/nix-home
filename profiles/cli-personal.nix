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
    ./cli.nix
    ../modules/gemini-cli
    ../modules/jujutsu
    ../modules/ssh/personal.nix
  ];
}
