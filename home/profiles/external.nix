{ inputs, ... }:
{
  imports = [
    inputs.chromium-pwa-wmclass-sync.homeManagerModules.default
    inputs.direnv-instant.homeModules.direnv-instant
    inputs.sops-nix.homeManagerModules.sops
    inputs.xremap.homeManagerModules.default
  ];
}
