{ ... }:
{
  dconf.settings = {
    "org/gnome/shell" = {
      favorite-apps = [
        "obsidian.desktop"
        "Google Gemini.desktop"
        "Duckie.desktop"
        "google-chrome.desktop"
        "Cider.desktop"
        "org.gnome.Ptyxis.desktop"
        "Gmail.desktop"
        "Google Chat.desktop"
        "Google Meet.desktop"
        "Google Calendar.desktop"
        "spotify.desktop"
        "WhatsApp Web.desktop"
        "1password.desktop"
      ];
    };
  };

  imports = [
    ./gui.nix
    ../modules/1password
    ../modules/vscode
  ];
}
