{ pkgs, ... }:
{

  programs.gamemode.enable = true;

  # Auto-nice processes by name (cargo, rustc, cc, etc. get low priority;
  # games get high priority) — works regardless of how the process is launched
  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-rules-cachyos;
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
        { sku = "FORC-FDEV-DO-1000"; filter = "edo"; }
        { sku = "FORC-FDEV-DO-38-IN-40"; filter = "edh4"; }
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
}
