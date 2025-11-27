{ lib, ... }:
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
}