{
  config,
  pkgs,
  ...
}:
let
  guiApps = with pkgs; [
    beeper
    cameractrls-gtk4
    mission-center
    obsidian
    spotify
  ];
in
{
  programs.chromium-pwa-wmclass-sync.service.enable = true;

  home.packages = (map (p: config.lib.nixGL.wrap p) guiApps);

  imports = [
    ../modules/1password
    ../modules/fonts
    ../modules/gnome
    ../modules/ptyxis
  ];
}
