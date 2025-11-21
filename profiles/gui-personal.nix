{ pkgs, config, ... }:
let
  geminiDesktopItem = pkgs.makeDesktopItem {
    name = "google-gemini";
    desktopName = "Google Gemini";
    genericName = "AI Assistant";
    exec = builtins.concatStringsSep " " [
      "${pkgs.google-chrome}/bin/google-chrome-stable"
      "--app=https://gemini.google.com/app"
    ];
    icon = "${pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/lobehub/lobe-icons/refs/heads/master/packages/static-svg/icons/gemini-color.svg";
      sha256 = "sha256-1xYepahcUdmWu3YRxmXptTHbWkCS1JeO1Nbd9sBDJX0=";
    }}";
    categories = [ "Network" ];
    startupWMClass = "chrome-gemini.google.com__app-Default";
    terminal = false;
  };
in
{
  home.packages =
    with pkgs;
    let
      guiApps = [
        baobab
        brave
        claude-code
        firefox
        gnome-calculator
        gnome-extension-manager
        gnome-logs
        gnome-text-editor
        loupe
        papers
        seabird
      ];
    in
    (map (p: config.lib.nixGL.wrap p) guiApps);

  dconf.settings = {
    "org/gnome/shell" = {
      favorite-apps = [
        "google-gemini.desktop"
        "google-chrome.desktop"
        "org.gnome.Ptyxis.desktop"
        "code.desktop"
        "spotify.desktop"
        "1password.desktop"
        "org.gnome.Nautilus.desktop"
      ];
    };
  };

  home.file.".local/share/applications/google-gemini.desktop".source =
    "${geminiDesktopItem}/share/applications/google-gemini.desktop";

  imports = [
    ./gui.nix
    ../modules/1password/personal.nix
    ../modules/easyeffects
    ../modules/vscode/personal.nix
  ];
}
