{ ... }:
{
  imports = [
    ./config.nix
    ./disk.nix
    ./hardware.nix
    ./hydration.nix
    ../../profiles/lenovo-thinkpad-z16-gen1.nix
  ];
}
