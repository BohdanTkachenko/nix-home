# AMD GPU configuration
{ pkgs, ... }:
{
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
}
