{ pkgs, config, ... }:
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
    ../modules/1password/personal.nix
    ../modules/easyeffects
    ../modules/vscode/personal.nix
  ];
}
