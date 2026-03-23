# HiDPI display configuration
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.hardware.hidpi;
in
{
  options.my.hardware.hidpi.enable = lib.mkEnableOption "HiDPI display support";

  config = lib.mkIf cfg.enable {
    console = {
      font = "${pkgs.terminus_font}/share/consolefonts/ter-u28n.psf.gz";
    };

    services.xserver.dpi = 180;
  };
}
