{ lib, pkgs, ... }:
{
  imports = [
    ../nixos/common.nix
    ../nixos/hardware/common.nix
    ../nixos/hardware/cpu-intel.nix
    ../nixos/hardware/gpu-nvidia.nix
    ../nixos/hardware/bluetooth.nix
    ../nixos/hardware/keychron.nix
    ../nixos/hardware/moonlander.nix
    ../nixos/hardware/ssd.nix
    ../nixos/hydration-common.nix
    (import ../nixos/disk-luks-btrfs.nix {
      diskDevice = "/dev/disk/by-id/nvme-WD_BLACK_SN850X_4000GB_23402H800030";
    })
  ];

  networking.hostName = lib.mkDefault "nyancat";

  home-manager.users.dan.imports = [
    ../home/hardware/pc-personal.nix
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
}
