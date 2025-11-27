# Laptop-specific hardware features
{ ... }:
{
  services = {
    power-profiles-daemon.enable = true;
    fprintd.enable = true;
    tlp.enable = false;
  };
}