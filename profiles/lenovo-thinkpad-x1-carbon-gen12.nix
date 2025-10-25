{ ... }:
{
  services.xremap.config.modmap = [
    {
      name = "Remap special function keys to media keys";
      remap = {
        # "KEY_447" = "KEY_PLAYPAUSE";
        "KEY_SWITCHVIDEOMODE" = "KEY_PLAYPAUSE";
        "KEY_SELECTIVE_SCREENSHOT" = "KEY_PREVIOUSSONG";
      };
    }
  ];

  imports = [
    ./lenovo-thinkpad.nix
  ];
}
