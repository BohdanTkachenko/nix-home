{ lib, pkgs, ... }:
{
  # programs.gnome-shell = {
  #   enable = true;
  #   extensions = with pkgs.gnomeExtensions; [
  #     { package = xremap; }
  #   ];
  # };

  services.xremap = {
    enable = lib.mkForce true;
    watch = true;
    mouse = true;
    withGnome = true;
    config.keymap = [
      {
        name = "Easy tab switch in Chrome";
        remap = {
          "C-left" = "C-pageup";
          "C-right" = "C-pagedown";
        };
      }
      {
        name = "Disable mouse middle click";
        remap = {
          BTN_MIDDLE = "KEY_RESERVED";
        };
      }
    ];
  };
}
