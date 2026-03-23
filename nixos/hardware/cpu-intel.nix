# Intel CPU configuration
{
  config,
  lib,
  ...
}:
let
  cfg = config.my.hardware.cpu.intel;
in
{
  options.my.hardware.cpu.intel.enable = lib.mkEnableOption "Intel CPU support";

  config = lib.mkIf cfg.enable {
    boot.kernelModules = [ "kvm-intel" ];
    hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };
}
