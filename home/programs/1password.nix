{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.packages = [ (config.lib.nixGL.wrap pkgs._1password-gui) ];
}
