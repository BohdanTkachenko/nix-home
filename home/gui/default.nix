{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:
{
  imports = [
    ./common.nix
    ../programs/easyeffects.nix
  ];

  config = lib.mkMerge [
    (lib.mkIf (config.my.environment == "personal") {
      home.packages =
        (with pkgs; [
          alpaca
          baobab
          brave
          discord
          fractal
          teamspeak6-client
          ticktick
          gnome-calculator
          gimp
          gnome-extension-manager
          gnome-logs
          gnome-text-editor
          inkscape
          jstest-gtk
          loupe
          mailspring
          papers
          protonvpn-gui
          seabird
          transmission_4-gtk
          wireshark
          xournalpp

          # 3D printing
          bambu-studio
          freecad
          openscad-unstable
          orca-slicer
        ])
        ++ (with pkgs-unstable; [
          antigravity
          mcpelauncher-ui-qt
        ]);

      dconf.settings = {
        "org/gnome/shell" = {
          favorite-apps = [
            "Google Gemini.desktop"
            "google-chrome.desktop"
            "org.gnome.Ptyxis.desktop"
            "code.desktop"
            "WhatsApp Web.desktop"
            "Messages.desktop"
            "spotify.desktop"
            "1password.desktop"
            "org.gnome.Nautilus.desktop"
          ];
        };
      };
    })
  ];
}
