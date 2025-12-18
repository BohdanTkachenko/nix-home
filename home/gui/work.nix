{
  config,
  pkgs,
  ...
}:
{
  home.packages =
    with pkgs;
    let
      guiApps = [
        google-chrome
        google-chrome-beta
      ];
    in
    (map (p: config.lib.nixGL.wrap p) guiApps);

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
  ];
}
