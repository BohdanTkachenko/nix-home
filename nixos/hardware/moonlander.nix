# ZSA Moonlander keyboard support
{
  config,
  lib,
  ...
}:
let
  cfg = config.my.hardware.moonlander;
in
{
  options.my.hardware.moonlander.enable = lib.mkEnableOption "ZSA Moonlander keyboard support";

  config = lib.mkIf cfg.enable {
    hardware.keyboard.zsa.enable = true;
  };
}
