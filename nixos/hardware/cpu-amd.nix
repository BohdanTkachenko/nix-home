# AMD CPU configuration
{
  config,
  lib,
  ...
}:
let
  cfg = config.my.hardware.cpu.amd;
in
{
  options.my.hardware.cpu.amd.enable = lib.mkEnableOption "AMD CPU support";

  config = lib.mkIf cfg.enable {
    boot = {
      kernelModules = [ "kvm-amd" ];
      kernelParams = [ "amd_pstate=active" ];
    };
    hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    services.thermald.enable = false;
  };
}
