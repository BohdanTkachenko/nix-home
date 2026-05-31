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

  # Dual-CCD X3D desktop part (e.g. 9950X3D): CCD0 carries the V-cache, CCD1
  # is the higher-boost compute die. Enables topology-aware tuning that
  # hardcodes this chip's core ranges (CCD pinning) — keep off on single-CCD
  # / mobile AMD parts where those ranges don't exist.
  options.my.hardware.cpu.amd.x3d.enable =
    lib.mkEnableOption "AMD X3D dual-CCD topology optimizations";

  config = lib.mkIf cfg.enable {
    boot = {
      kernelModules = [ "kvm-amd" ];
      kernelParams = [ "amd_pstate=active" ];
    };
    hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    services.thermald.enable = false;
  };
}
