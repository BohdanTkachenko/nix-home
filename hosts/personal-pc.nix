{ lib, pkgs, ... }:
{
  nixpkgs.config.permittedInsecurePackages = [
    "mbedtls-2.28.10"
  ];

  imports = [
    ../nixos/common.nix
    ../nixos/wireguard.nix
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

  home-manager.sharedModules = [
    ../home/hardware/pc-personal.nix
  ];
}
