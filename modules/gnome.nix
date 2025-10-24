{ lib, pkgs, ... }:

let
  profileUuid = "C0FFEE-C0DE-FEED-FACE-AC1DDEADBEEF";
in

{
  home.packages = with pkgs; [
    adw-gtk3
  ];

  xdg = {
    enable = true;
    mime.enable = true;

    autostart = {
      enable = true;
      entries = [
        "${pkgs._1password-gui}/share/applications/1password.desktop"
        "${pkgs.beeper}/share/applications/beepertexts.desktop"
      ];
    };
  };

  systemd.user.sessionVariables.NIXOS_OZONE_WL = "1";

  gtk = {
    enable = true;
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
  };

  programs.gnome-shell = {
    enable = true;
    extensions = with pkgs.gnomeExtensions; [
      { package = appindicator; }
      { package = blur-my-shell; }
      { package = caffeine; }
      { package = dash-to-dock; }
      { package = search-light; }
      { package = xremap; }
    ];
  };

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

    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "adw-gtk3-dark";
      gtk-enable-primary-paste = false;
      show-battery-percentage = true;
    };

    "org/gnome/desktop/wm/keybindings" = {
      close = [ "<Shift><Control>q" ];
      switch-applications = [ "<Control>Tab" ];
      switch-applications-backward = [ "<Shift><Control>Tab" ];
      switch-group = [ "<Control>grave" ];
      switch-group-backward = [ "<Shift><Control>grave" ];
    };

    "org/gnome/desktop/wm/preferences" = {
      button-layout = "close,minimize,maximize:";
    };

    "org/gnome/mutter" = {
      overlay-key = "Super_R";
    };

    "org/gnome/settings-daemon/plugins/media-keys" = {
      next = [ "AudioNext" ];
      play = [ "AudioPlay" ];
      previous = [ "AudioPrev" ];
    };

    "org/gnome/Ptyxis/Shortcuts" = {
      close-tab = "<Control>w";
      close-window = "";
      copy-clipboard = "<Control>c";
      new-tab = "<Control>t";
      new-window = "<Control>n";
      paste-clipboard = "<Control>v";
      reset = "'<Shift><Control>r'";
      search = "<Shift><Control>f";
      select-all = "<Control>a";
    };

    "org/gnome/Ptyxis" = {
      default-profile-uuid = profileUuid;
      profile-uuids = [ profileUuid ];
    };

    "org/gnome/Ptyxis/Profiles/${profileUuid}" = {
      label = "The Coffee Coder";
      opacity = lib.gvariant.mkDouble 0.9;
      palette = "Japanesque";
    };

    "org/gnome/shell/extensions/caffeine" = {
      show-notifications = false;
    };

    "org/gnome/shell/extensions/dash-to-dock" = {
      dock-fixed = true;
      show-apps-at-top = true;
      always-center-icons = true;
    };

    "org/gnome/shell/extensions/search-light" = {
      shortcut-search = [ "<Control>space" ];
      popup-at-cursor-monitor = true;
    };
  };
}
