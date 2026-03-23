# Touchpad configuration
{
  config,
  lib,
  ...
}:
let
  cfg = config.my.hardware.touchpad;
in
{
  options.my.hardware.touchpad.enable = lib.mkEnableOption "touchpad support";

  config = lib.mkIf cfg.enable {
    services.libinput = {
      enable = true;
      touchpad = {
        accelSpeed = "0.3";
        clickMethod = "clickfinger";
        disableWhileTyping = true;
        scrollMethod = "twofinger";
        naturalScrolling = true;
        tapping = false;
      };
    };
  };
}
