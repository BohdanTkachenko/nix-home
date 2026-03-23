# SSD optimization configuration
{
  config,
  lib,
  ...
}:
let
  cfg = config.my.hardware.ssd;
in
{
  options.my.hardware.ssd.enable = lib.mkEnableOption "SSD optimizations";

  config = lib.mkIf cfg.enable {
    # Weekly TRIM for SSD maintenance
    services.fstrim.enable = true;
  };
}
