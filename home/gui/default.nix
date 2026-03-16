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
        ]);

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
    })
    (lib.mkIf (config.my.environment == "work") {
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
    })
  ];
}
