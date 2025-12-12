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
    withGnome = true;
    config.keymap = [
      {
        name = "Easy tab switch in Chrome";
        remap = {
          "C-left" = "C-pageup";
          "C-right" = "C-pagedown";
        };
      }
    ];
  };
}
