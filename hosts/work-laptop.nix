{ ... }:
{
  imports = [
    ../home/common.nix
    ../home/hardware/gpu-amd.nix
    ../home/hardware/lenovo-thinkpad-x1-carbon-gen12.nix
    ../home/work.nix
  ];

  nixpkgs.config.allowUnfree = true;
  services.xremap.enable = false;
}
