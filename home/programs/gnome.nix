{ lib, pkgs, ... }:
{
  home.packages = with pkgs; [
    adw-gtk3
    adwaita-icon-theme
    gnome-themes-extra
  ];

  xdg = {
    enable = true;
    mime.enable = true;

    autostart = {
      enable = true;
      entries = [
        "${
          pkgs.makeDesktopItem {
            name = "1password-silent";
            desktopName = "1Password";
            exec = "${pkgs._1password-gui}/bin/1password -silent";
          }
        }/share/applications/1password-silent.desktop"

        "${pkgs.spotify}/share/applications/spotify.desktop"

        "${pkgs.webApps.stable.googleMessages}/share/applications/google-messages-stable.desktop"
        "${pkgs.webApps.stable.whatsApp}/share/applications/whatsapp-stable.desktop"
      ];
    };
  };

  systemd.user.sessionVariables.NIXOS_OZONE_WL = "1";

  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
  };

  programs.gnome-shell = {
    enable = true;
    extensions = with pkgs.gnomeExtensions; [
      { package = appindicator; }
      { package = blur-my-shell; }
      { package = caffeine; }
      { package = dash-to-dock; }
      { package = just-perfection; }
      # { package = paperwm; }
      { package = search-light; }
      { package = tiling-shell; }
      { package = bing-wallpaper-changer; }
    ];
  };

  dconf.settings = with lib.hm.gvariant; {
    "org/gnome/desktop/session" = {
      idle-delay = 900;
    };

    "org/gnome/shell/extensions/just-perfection" = {
      quick-settings-airplane-mode = false;
      startup-status = 0;
    };

    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-battery-timeout = 1800;
      sleep-inactive-ac-timeout = 3600;
    };

    "org/gnome/shell/extensions/bingwallpaper" = {
      icon-name = "low-frame-symbolic";
      random-mode-include-only-uhd = true;
    };

    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      icon-theme = "Adwaita";
      gtk-enable-primary-paste = false;
      show-battery-percentage = true;
      enable-hot-corners = false;
    };

    "org/gnome/desktop/peripherals/mouse" = {
      natural-scroll = true;
    };

    "org/gnome/desktop/peripherals/touchpad" = {
      tap-to-click = false;
    };

    "org/gnome/desktop/input-sources" = {
      xkb-options = [
        "grp:sclk_toggle"
        "grp:toggle"
      ];
      sources = [
        (mkTuple [
          "xkb"
          "us"
        ])
        (mkTuple [
          "xkb"
          "ua"
        ])
      ];
    };

    "org/gnome/desktop/wm/keybindings" = {
      close = [ "<Shift><Control>q" ];
      switch-applications = [ "<Control>Tab" ];
      switch-applications-backward = [ "<Shift><Control>Tab" ];
      switch-group = [ "<Control>grave" ];
      switch-group-backward = [ "<Shift><Control>grave" ];
      switch-to-workspace-left = [ ];
      switch-to-workspace-right = [ ];
    };

    "org/gnome/desktop/wm/preferences" = {
      button-layout = "':minimize,maximize,close";
    };

    "org/gnome/mutter" = {
      experimental-features = [
        "scale-monitor-framebuffer"
        "variable-refresh-rate"
        "xwayland-native-scaling"
      ];

      overlay-key = "Super_R";
    };

    "org/gnome/settings-daemon/plugins/media-keys" = {
      next = [ "AudioNext" ];
      play = [ "AudioPlay" ];
      previous = [ "AudioPrev" ];
    };

    "org/gnome/shell/extensions/caffeine" = {
      show-notifications = false;
    };

    "org/gnome/shell/extensions/dash-to-dock" = {
      always-center-icons = true;
      apply-custom-theme = true;
      click-action = "focus-or-appspread";
      custom-theme-shrink = false;
      dash-max-icon-size = 64;
      dock-fixed = true;
      extend-height = false;
      hot-keys = false;
      isolate-monitors = true;
      show-apps-at-top = true;
      show-show-apps-button = false;
      show-trash = false;
    };

    "org/gnome/shell/extensions/search-light" = {
      shortcut-search = [ "<Control>space" ];
      popup-at-cursor-monitor = true;
    };
  };
}
