{ pkgs, ... }:
{
  services.xremap = {
    enable = true;
    package = pkgs.xremap.gnome;
    deviceNames = [ "AT Translated Set 2 keyboard" ];
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
