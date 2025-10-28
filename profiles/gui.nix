{
  config,
  pkgs,
  claude-desktop,
  ...
}:
let
  guiApps = with pkgs; [
    _1password-gui
    beeper
    cameractrls-gtk4
    claude-desktop.packages.${pkgs.system}.claude-desktop
    mission-center
    obsidian
    solaar
    spotify
  ];
in
{
  programs.chromium-pwa-wmclass-sync.service.enable = true;

  home.packages = (map (p: config.lib.nixGL.wrap p) guiApps);

  imports = [
    ../modules/fonts
    ../modules/gnome
    ../modules/ptyxis
  ];
}
