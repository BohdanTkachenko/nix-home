{ ... }:
{
  imports = [
    ./modules/anti-drift.nix
    ./modules/options.nix
  ];

  anti-drift.driftDir = "$HOME/.config/nix/drifts";

  home.stateVersion = "25.11";
  programs.home-manager.enable = true;
  targets.genericLinux.enable = true;
}
