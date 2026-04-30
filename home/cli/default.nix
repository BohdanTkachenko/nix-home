{ config, lib, pkgs, pkgs-unstable, ... }:
let
  pinToCCD1 = import ../../lib/pin-to-ccd1.nix { inherit pkgs; };
in
{
  imports = [
    ./common.nix
    ../programs/ai/claude-code.nix
  ];

  config = lib.mkIf (config.my.environment == "personal") {
    home.packages = with pkgs-unstable; [
      act
      (pinToCCD1 codex)
      gh
      glab
      (pinToCCD1 opencode)
    ];
  };
}
