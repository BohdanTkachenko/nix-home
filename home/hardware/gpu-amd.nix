{ nixgl, lib, ... }:
{
  # nixGL is only needed on non-NixOS systems (nixgl is null on NixOS)
  targets.genericLinux.nixGL = lib.mkIf (nixgl != null) {
    packages = nixgl.packages;
    defaultWrapper = "mesa";
    installScripts = [ "mesa" ];
    vulkan.enable = true;
  };
}
