{
  config,
  nixgl,
  pkgs,
  ...
}:
let
  guiApps = with pkgs; [
    _1password-gui
    beeper
    cameractrls-gtk4
    mission-center
    obsidian
    spotify
  ];
in
{
  programs.chromium-pwa-wmclass-sync.service.enable = true;

  nixGL.packages = nixgl.packages;
  nixGL.vulkan.enable = true;

  home.packages = (map (p: config.lib.nixGL.wrap p) guiApps);

  imports = [
    ../modules/fonts
    ../modules/gnome
    ../modules/ptyxis
    ../modules/vscode
  ];
}
