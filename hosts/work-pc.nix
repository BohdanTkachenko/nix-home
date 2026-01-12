{ ... }:
{
  imports = [
    ../overlays
    ../home/common.nix
    ../home/hardware/gpu-amd.nix
    ../home/hardware/pc-work.nix
    ../home/work.nix
  ];

  home.homeDirectory = "/usr/local/google/home/bohdant";

  nixpkgs.config.allowUnfree = true;
  services.xremap.enable = false;
}
