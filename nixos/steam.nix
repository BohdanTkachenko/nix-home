{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:
{
  config = lib.mkIf config.my.gaming.enable {

    # Stop Steam and Wine/Proton early during shutdown. Steam's Proton runtime
    # spawns winedevice.exe processes that ignore SIGTERM and keep hammering
    # D-Bus for udisks2 activation as the bus is going down. Without this,
    # the user session scope hits systemd's 90s DefaultTimeoutStopSec before
    # SIGKILL fires, adding ~90s to every reboot when Steam is running.
    #
    # We give them 10 seconds to exit cleanly via SIGTERM (so Steam can flush
    # cloud saves, etc.), then SIGKILL anything still alive.
    #
    # Ordering: After=user.slice means stop-order is reversed during shutdown,
    # so this unit's ExecStop fires before user.slice tears down user sessions
    # — letting us reap Wine before user@.service tries to (and fails to) stop
    # it gracefully.
    systemd.services.kill-steam-on-shutdown = {
      description = "Stop Steam/Wine on shutdown (graceful, then force)";
      wantedBy = [ "multi-user.target" ];
      after = [ "user.slice" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        # Cap our own stop time so the 10s grace + cleanup never blows past 15s.
        TimeoutStopSec = "15s";
        ExecStart = "${pkgs.coreutils}/bin/true";
        ExecStop = pkgs.writeShellScript "kill-steam-on-shutdown" ''
          set -u
          ${pkgs.procps}/bin/pkill -TERM -x steam || true
          ${pkgs.procps}/bin/pkill -TERM -f 'wine|proton' || true

          # Up to 10s for graceful exit; bail early once everything is gone.
          for _ in $(${pkgs.coreutils}/bin/seq 1 10); do
            if ! ${pkgs.procps}/bin/pgrep -x steam >/dev/null \
               && ! ${pkgs.procps}/bin/pgrep -f 'wine|proton' >/dev/null; then
              exit 0
            fi
            ${pkgs.coreutils}/bin/sleep 1
          done

          ${pkgs.procps}/bin/pkill -KILL -x steam || true
          ${pkgs.procps}/bin/pkill -KILL -f 'wine|proton' || true
          exit 0
        '';
      };
    };

    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      gamescopeSession.enable = true;
      extraPackages = with pkgs; [
        adwaita-icon-theme
        min-ed-launcher
      ];
      package = pkgs.steam.override {
        extraEnv = {
          MANGOHUD = true;
          DXVK_HUD = "compiler";
        };
      };
    };

    environment.systemPackages = with pkgs; [
      edmarketconnector
      pkgs-unstable.lutris
      mangohud
    ];

    home-manager.users.dan.anti-drift.files.".config/min-ed-launcher/settings.json" = {
      source = (pkgs.formats.json { }).generate "min-ed-launcher-settings.json" {
        apiUri = "https://api.zaonce.net";
        watchForCrashes = false;
        language = null;
        autoUpdate = false;
        checkForLauncherUpdates = false;
        maxConcurrentDownloads = 4;
        forceUpdate = "";
        processes = [
          {
            fileName = "${pkgs.edmarketconnector}/bin/edmarketconnector";
            keepOpen = true;
          }
        ];
        shutdownProcesses = [ ];
        filterOverrides = [
          {
            sku = "FORC-FDEV-DO-1000";
            filter = "edo";
          }
          {
            sku = "FORC-FDEV-DO-38-IN-40";
            filter = "edh4";
          }
        ];
        additionalProducts = [ ];
      };
      json = true;
    };

    home-manager.users.dan.xdg.autostart.entries = [
      "${
        pkgs.makeDesktopItem {
          name = "steam-silent";
          desktopName = "Steam Silent";
          exec = "steam -silent";
        }
      }/share/applications/steam-silent.desktop"
    ];

    home-manager.users.dan.xdg.desktopEntries.overwatch2 = {
      name = "Overwatch 2";
      comment = "Play this game on Steam";
      exec = "steam steam://rungameid/2357570";
      icon = "steam_icon_2357570";
      terminal = false;
      type = "Application";
      categories = [ "Game" ];
      settings.StartupWMClass = "steam_app_2357570";
    };

    home-manager.users.dan.xdg.desktopEntries.eliteDangerous = {
      name = "Elite Dangerous";
      comment = "Play this game on Steam";
      exec = "steam steam://rungameid/359320";
      icon = "steam_icon_359320";
      terminal = false;
      type = "Application";
      categories = [ "Game" ];
      settings.StartupWMClass = "steam_app_359320";
    };
  };
}
