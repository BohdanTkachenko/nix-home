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

  home.packages =
    with pkgs;
    (map (p: config.lib.nixGL.wrap p) guiApps)
    ++ [
      nerd-fonts.hack
      nerd-fonts.droid-sans-mono
      nerd-fonts.roboto-mono
    ];

  imports = [
    ../modules/gnome
    ../modules/ptyxis
    ../modules/vscode/vscode.nix
  ];
}
