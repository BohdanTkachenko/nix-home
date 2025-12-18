{ pkgs, config, ... }:
{
  home.packages = with pkgs; [
    baobab
    brave
    firefox
    gnome-calculator
    gnome-extension-manager
    gnome-logs
    gnome-text-editor
    loupe
    mailspring
    papers
    protonvpn-gui
    seabird
    transmission_4-gtk
  ];

  dconf.settings = {
    "org/gnome/shell" = {
      favorite-apps = [
        "Google Gemini.desktop"
        "google-chrome.desktop"
        "org.gnome.Ptyxis.desktop"
        "code.desktop"
        "spotify.desktop"
        "1password.desktop"
        "org.gnome.Nautilus.desktop"
      ];
    };
  };

  imports = [
    ./common.nix
    ../programs/easyeffects
  ];
}
