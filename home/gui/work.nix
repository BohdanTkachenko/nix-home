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
    ./common.nix
    ../programs/1password/work.nix
    ../programs/vscode/work.nix
    ../programs/google-chrome/default.nix
  ];
}
