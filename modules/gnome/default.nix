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
        "${pkgs._1password-gui}/share/applications/1password.desktop"
      ];
    };
  };

  systemd.user.sessionVariables.NIXOS_OZONE_WL = "1";

  gtk = {
    enable = true;
  };

  programs.gnome-shell = {
    enable = true;
    extensions = with pkgs.gnomeExtensions; [
      { package = appindicator; }
      { package = blur-my-shell; }
      { package = caffeine; }
      { package = dash-to-dock; }
      { package = junk-notification-cleaner; }
      { package = just-perfection; } # temporary
      # { package = paperwm; }
      { package = search-light; }
      { package = tiling-shell; }
      # { package = bing-wallpaper-changer ;}
    ];
  };

  dconf.settings = with lib.hm.gvariant; {
    "org/gnome/mutter" = {
      experimental-features = "['scale-monitor-framebuffer']";
    };

    "org/gnome/desktop/session" = {
      idle-delay = 900;
    };

    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-battery-timeout = 1800;
      sleep-inactive-ac-timeout = 3600;
    };

    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "adw-gtk3-dark";
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
      xkb-options = [ "grp:sclk_toggle" ];
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
