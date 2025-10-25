{ nixgl, ... }:
{
  nixGL.packages = nixgl.packages;
  nixGL.defaultWrapper = "mesa";
  nixGL.installScripts = [ "mesa" ];
  nixGL.vulkan.enable = true;
}
