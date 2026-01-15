{ pkgs-unstable, ... }:
{
  home.packages = with pkgs-unstable; [
    act
    gh
    glab
  ];

  imports = [
    ./common.nix
    ../programs/ai/ask.nix
    ../programs/ai/claude-code.nix
  ];
}
