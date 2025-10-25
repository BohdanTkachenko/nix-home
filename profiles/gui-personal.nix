{ ... }:
{
  dconf.settings = {
    "org/gnome/shell" = {
      favorite-apps = [
        "Gemini.desktop"
        "com.google.Chrome.desktop"
        "org.gnome.Ptyxis.desktop"
        "code.desktop"
        "com.spotify.Client.desktop"
        "beepertexts.desktop"
        "1password.desktop"
        "org.gnome.Nautilus.desktop"
      ];
    };
  };

  imports = [
    ../modules/easyeffects
    ../modules/flatpak
    ../modules/gemini-cli/gemini-cli.nix
  ];
}
