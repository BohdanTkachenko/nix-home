{ ... }:
{
  imports = [
    ../overlays
  ];

  home.stateVersion = "25.11";
  programs.home-manager.enable = true;
  targets.genericLinux.enable = true;
}
