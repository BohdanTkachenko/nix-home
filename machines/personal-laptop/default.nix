{ lib, ... }:
{
  imports = [
    ../common.nix
    ../hardware-common.nix
    ../hardware-cpu-amd.nix
    ../hardware-gpu-amd.nix
    ../hardware-laptop-lenovo-z16-gen1.nix
    ../hardware-bluetooth.nix
    ../hardware-touchpad.nix
    ../hardware-hidpi.nix
    ../hardware-ssd.nix
    ../hydration-common.nix
    (import ../disk-luks-btrfs.nix {
      diskDevice = "/dev/disk/by-id/nvme-Samsung_SSD_980_PRO_2TB_S6B0NG0R703558Y";
    })
  ];

  networking.hostName = lib.mkDefault "dan-idea";

  home-manager.users.dan.imports = [
    ../../profiles/lenovo-thinkpad-z16-gen1.nix
  ];
}
