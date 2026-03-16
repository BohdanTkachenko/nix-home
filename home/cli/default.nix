{ config, lib, pkgs-unstable, ... }:
{
  imports = [
    ./common.nix
    ../programs/ai/claude-code.nix
  ];

  config = lib.mkIf (config.my.environment == "personal") {
    home.packages = with pkgs-unstable; [
      act
      gh
      glab
      opencode
    ];
  };
}
