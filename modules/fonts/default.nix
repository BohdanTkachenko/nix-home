{ pkgs, ... }:
let
  emojiFontName = "Noto Color Emoji";
  fontName = "Adwaita Sans 12";
  monospaceFontName = "MesloLGL Nerd Font Mono 12";
in
{

  home.packages = with pkgs; [
    adwaita-fonts
    nerd-fonts.meslo-lg
    noto-fonts-color-emoji
  ];

  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      emoji = [ emojiFontName ];
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
