{ lib, ... }:
{
  imports = [
    ../machines/common.nix
    ../machines/hardware-common.nix
    ../machines/hardware-cpu-amd.nix
    ../machines/hardware-gpu-amd.nix
    ../machines/hardware-laptop-lenovo-z16-gen1.nix
    ../machines/hardware-bluetooth.nix
    ../machines/hardware-touchpad.nix
    ../machines/hardware-hidpi.nix
    ../machines/hardware-ssd.nix
    ../machines/hydration-common.nix
    (import ../machines/disk-luks-btrfs.nix {
      diskDevice = "/dev/disk/by-id/nvme-Samsung_SSD_980_PRO_2TB_S6B0NG0R703558Y";
    })
  ];

  networking.hostName = lib.mkDefault "dan-idea";

  home-manager.users.dan.imports = [
    ../profiles/lenovo-thinkpad-z16-gen1.nix
  ];
}
