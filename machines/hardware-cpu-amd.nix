# AMD CPU configuration
{
  config,
  lib,
  ...
}:
{
  boot = {
    kernelModules = [ "kvm-amd" ];
    kernelParams = ["amd_pstate=active"];
  };
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  services.thermald.enable = false;
}