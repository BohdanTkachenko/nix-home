{ pkgs, ... }:
{
  home.packages = with pkgs; [
    baobab
    brave
    firefox
    gnome-calculator
    gnome-extension-manager # TODO: remove
    gnome-logs
    gnome-text-editor
    google-chrome
    loupe
    papers
  ];

  dconf.settings = {
    "org/gnome/shell" = {
      favorite-apps = [
        "Gemini.desktop"
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
    ../modules/easyeffects
    ../modules/gemini-cli/gemini-cli.nix
  ];
}
