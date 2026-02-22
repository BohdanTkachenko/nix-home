{ ... }:
{
  imports = [
    ./modules/anti-drift.nix
    ./registry.nix
  ];

  anti-drift.driftDir = "/home/dan/.config/nix/drifts";

  home.stateVersion = "25.11";
  programs.home-manager.enable = true;
  targets.genericLinux.enable = true;
}
