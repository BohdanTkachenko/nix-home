{ pkgs, ... }:
let
  fontName = "Adwaita Sans 12";
  monospaceFontName = "MesloLGL Nerd Font Mono 12";
in
{

  home.packages = with pkgs; [
    adwaita-fonts
    nerd-fonts.meslo-lg
  ];

  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      monospace = [ monospaceFontName ];
      sansSerif = [ fontName ];
      serif = [ fontName ];
    };
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      font-name = fontName;
      document-font-name = fontName;
      monospace-font-name = monospaceFontName;
    };
  };
}
