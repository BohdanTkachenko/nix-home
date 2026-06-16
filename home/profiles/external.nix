{ inputs, ... }:
{
  imports = [
    inputs.chromium-pwa-wmclass-sync.homeManagerModules.default
    inputs.direnv-instant.homeModules.direnv-instant
    inputs.xremap.homeManagerModules.default
  ];
}
