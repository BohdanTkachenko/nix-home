{
  pkgs,
  config,
  ...
}:
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
    teamspeak_server
    teamspeak6-client
    transmission_4-gtk
    xournalpp
  ];

  dconf.settings = {
    "org/gnome/shell" = {
      favorite-apps = [
        "google-gemini-stable.desktop"
        "google-chrome.desktop"
        "org.gnome.Ptyxis.desktop"
        "code.desktop"
        "whatsapp-stable.desktop"
        "google-messages-stable.desktop"
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
