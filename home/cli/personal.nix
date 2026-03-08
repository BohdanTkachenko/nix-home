{ pkgs-unstable, ... }:
{
  home.packages = with pkgs-unstable; [
    act
    gh
    glab
    opencode
  ];

  imports = [
    ./common.nix
    ../programs/ai/claude-code.nix
  ];
}
