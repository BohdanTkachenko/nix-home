{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [ _1password-gui ];
}
