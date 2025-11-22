# Hardware configuration for ThinkPad Z16 Gen1
# AMD Ryzen 6000 series with AMD Radeon integrated/discrete graphics
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;

    initrd = {
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "thunderbolt"
        "usb_storage"
        "sd_mod"
      ];
      kernelModules = [ "amdgpu" ];
    };

    kernelModules = [ "kvm-amd" ];
    extraModulePackages = [ ];

    kernelParams = [
      "amdgpu.ppfeaturemask=0xffffffff"
      "amd_pstate=active"
    ];
  };

  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      amdvlk
      rocmPackages.clr.icd
    ];
    extraPackages32 = with pkgs; [
      driversi686Linux.amdvlk
    ];
  };

  hardware.enableRedistributableFirmware = true;
  hardware.enableAllFirmware = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  services.power-profiles-daemon.enable = true;
  services.thermald.enable = false; # Not needed for AMD
  services.fprintd.enable = true;
  services.tlp.enable = false;
}
