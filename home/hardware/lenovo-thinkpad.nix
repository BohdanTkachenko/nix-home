{ ... }:
{
  services.xremap.config.modmap = [
    {
      name = "Put modifier keys in more usable places";
      device.only = [ "AT Translated Set 2 keyboard" ];
      remap = {
        "Alt_L" = "Control_L";
        "Super_L" = "Alt_L";
        "Control_L" = "Super_L";
      };
    }
    {
      name = "Make CapsLock useful";
      device.only = [ "AT Translated Set 2 keyboard" ];
      remap = {
        "CapsLock" = "Backspace";
      };
    }
  ];
}
