{ ... }:
{
  services.xremap.config.modmap = [
    {
      name = "Remap special function keys to media keys";
      remap = {
        "KEY_PICKUP_PHONE" = "KEY_PREVIOUSSONG";
        "KEY_HANGUP_PHONE" = "KEY_PLAYPAUSE";
        "KEY_BOOKMARKS" = "KEY_NEXTSONG";
      };
    }
  ];

  imports = [
    ./lenovo-thinkpad.nix
  ];
}
