# AMD GPU configuration
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.hardware.gpu.amd;
in
{
  options.my.hardware.gpu.amd.enable = lib.mkEnableOption "AMD GPU support";

  config = lib.mkIf cfg.enable {
    boot = {
      initrd.kernelModules = [ "amdgpu" ];
      kernelParams = [
        "amdgpu.ppfeaturemask=0xffffffff"
      ];
    };

    hardware.graphics = {
      enable32Bit = true;
      extraPackages = with pkgs; [
        rocmPackages.clr.icd
      ];
    };
  };
}
