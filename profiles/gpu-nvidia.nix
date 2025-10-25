{ pkgs, nixgl, ... }:
{
  nixGL.packages = pkgs.callPackage "${nixgl}/nixGL.nix" {
    nvidiaVersion = "580.95.05";
  };
  nixGL.defaultWrapper = "nvidia";
  nixGL.installScripts = [ "nvidia" ];
  nixGL.vulkan.enable = true;
}
