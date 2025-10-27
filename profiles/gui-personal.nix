{ pkgs, config, ... }:
{
  home.packages =
    with pkgs;
    let
      guiApps = [
        baobab
        brave
        cilium-cli
        claude-code
        firefox
        gnome-calculator
        gnome-extension-manager
        gnome-logs
        gnome-text-editor
        google-chrome
        loupe
        papers
        seabird
      ];
    in
    (map (p: config.lib.nixGL.wrap p) guiApps);

  dconf.settings = {
    "org/gnome/shell" = {
      favorite-apps = [
        "Google Gemini.desktop"
        "google-chrome.desktop"
        "org.gnome.Ptyxis.desktop"
        "code.desktop"
        "spotify.desktop"
        "beepertexts.desktop"
        "1password.desktop"
        "org.gnome.Nautilus.desktop"
      ];
    };
  };

  imports = [
    ./gui.nix
    ../modules/easyeffects
    ../modules/vscode/personal.nix
  ];
}
