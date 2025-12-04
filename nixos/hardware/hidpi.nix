# HiDPI display configuration
{ pkgs, ... }:
{
  console = {
    font = "${pkgs.terminus_font}/share/consolefonts/ter-u28n.psf.gz";
  };

  services.xserver.dpi = 180;
}