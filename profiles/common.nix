{ ... }:
{
  home.stateVersion = "25.05";
  nixpkgs.config.allowUnfree = true;
  programs.home-manager.enable = true;
  targets.genericLinux.enable = true;
  services.xremap.enable = false;
}
