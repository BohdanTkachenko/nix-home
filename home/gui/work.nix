{
  config,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    google-chrome
    google-chrome-beta
  ];

  xdg.autostart.entries = [
    "${pkgs.webApps.stable.googleCalendar}/share/applications/google-calendar-stable.desktop"
    "${pkgs.webApps.stable.gmail}/share/applications/gmail-stable.desktop"
    "${pkgs.webApps.stable.googleChat}/share/applications/google-chat-stable.desktop"
  ];

  dconf.settings = {
    "org/gnome/shell" = {
      favorite-apps = [
        "obsidian.desktop"
        "google-gemini-stable.desktop"
        "Duckie.desktop"
        "google-chrome.desktop"
        "Cider.desktop"
        "org.gnome.Ptyxis.desktop"
        "gmail-stable.desktop"
        "google-chat-stable.desktop"
        "google-meet-stable.desktop"
        "google-calendar-stable.desktop"
        "spotify.desktop"
        "whatsapp-stable.desktop"
        "1password.desktop"
      ];
    };
  };

  imports = [
    ./common.nix
  ];
}
