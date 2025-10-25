{ ... }:
{
  services.xremap = {
    enable = true;
    withGnome = true;
    deviceNames = [
      "AT Translated Set 2 keyboard"
      "ThinkPad Extra Buttons"
    ];
    config.modmap = [
      {
        name = "Put modifier keys in more usable places";
        remap = {
          "Alt_L" = "Control_L";
          "Super_L" = "Alt_L";
          "Control_L" = "Super_L";
        };
      }
      {
        name = "Make CapsLock useful";
        remap = {
          "CapsLock" = "Backspace";
        };
      }
    ];
  };
}
