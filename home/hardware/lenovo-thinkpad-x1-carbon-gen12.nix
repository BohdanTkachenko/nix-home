{ ... }:
{
  services.xremap.config.modmap = [
    {
      name = "Remap special function keys to media keys";
      device.only = [ "ThinkPad Extra Buttons" ];
      remap = {
        # "KEY_447" = "KEY_PLAYPAUSE";
        "KEY_SWITCHVIDEOMODE" = "KEY_PLAYPAUSE";
        "KEY_SELECTIVE_SCREENSHOT" = "KEY_PREVIOUSSONG";
      };
    }
  ];

  imports = [
    ./common.nix
    ./lenovo-thinkpad.nix
  ];
}
