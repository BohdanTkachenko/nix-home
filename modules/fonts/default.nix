{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nerd-fonts.hack
    nerd-fonts.droid-sans-mono
    nerd-fonts.roboto-mono
  ];
}
