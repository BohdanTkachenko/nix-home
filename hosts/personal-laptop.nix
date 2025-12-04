{ lib, ... }:
{
  imports = [
    ../nixos/common.nix
    ../nixos/hardware/common.nix
    ../nixos/hardware/cpu-amd.nix
    ../nixos/hardware/gpu-amd.nix
    ../nixos/hardware/laptop-lenovo-z16-gen1.nix
    ../nixos/hardware/bluetooth.nix
    ../nixos/hardware/keychron.nix
    ../nixos/hardware/touchpad.nix
    ../nixos/hardware/hidpi.nix
    ../nixos/hardware/ssd.nix
    ../nixos/hydration-common.nix
    (import ../nixos/disk-luks-btrfs.nix {
      diskDevice = "/dev/disk/by-id/nvme-Samsung_SSD_980_PRO_2TB_S6B0NG0R703558Y";
    })
  ];

  networking.hostName = lib.mkDefault "dan-idea";

  home-manager.users.dan.imports = [
    ../profiles/lenovo-thinkpad-z16-gen1.nix
  ];
}
