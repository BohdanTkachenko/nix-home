{
  config,
  pkgs,
  ...
}:
{
  programs.chromium-pwa-wmclass-sync.service.enable = true;

  home.packages =
    with pkgs;
    let
      guiApps = [
        antigravity
        cameractrls-gtk4
        mission-center
        obsidian
        spotify
      ];
    in
    (map (p: config.lib.nixGL.wrap p) guiApps);

  registry.debian.packages = [
    "google-chrome-stable"
    "google-chrome-beta"
  ];

  xdg.autostart.entries = [
    "${pkgs.google-chrome}/share/applications/google-chrome.desktop"
  ];

  imports = [
    ../programs/1password.nix
    ../programs/fonts.nix
    ../programs/gnome.nix
    ../programs/ptyxis.nix
    ../programs/vscode
  ];
}
