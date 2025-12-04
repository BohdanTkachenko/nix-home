# SSD optimization configuration
{ ... }:
{
  # Weekly TRIM for SSD maintenance
  services.fstrim.enable = true;
}