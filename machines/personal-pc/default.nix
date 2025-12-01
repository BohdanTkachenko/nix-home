{ lib, pkgs, ... }:
{
  imports = [
    ../common.nix
    ../hardware-common.nix
    ../hardware-cpu-intel.nix
    ../hardware-gpu-nvidia.nix
    ../hardware-bluetooth.nix
    ../hardware-ssd.nix
    ../hydration-common.nix
    (import ../disk-luks-btrfs.nix {
      diskDevice = "/dev/disk/by-id/nvme-WD_BLACK_SN850X_4000GB_23402H800030";
    })
  ];

  networking.hostName = lib.mkDefault "nyancat";

  home-manager.users.dan.imports = [
    ../../profiles/pc-personal.nix
  ];

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    gamescopeSession.enable = true;
    extraPackages = with pkgs; [
      adwaita-icon-theme
    ];
    package = pkgs.steam.override {
      extraEnv = {
        MANGOHUD = true;
        DXVK_HUD = "compiler";
      };
    };
  };

  environment.systemPackages = with pkgs; [ mangohud ];

  home-manager.users.dan.xdg.autostart.entries = [
    "${pkgs.makeDesktopItem {
      name = "steam-silent";
      desktopName = "Steam Silent";
      exec = "steam -silent";
    }}/share/applications/steam-silent.desktop"
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
}