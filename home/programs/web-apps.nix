{ pkgs, ... }:
{
  home.packages = [
    pkgs.webApps.stable.googleGemini
    pkgs.webApps.stable.googleMeet
    pkgs.webApps.stable.googleMessages
    pkgs.webApps.stable.facebookMessenger
    pkgs.webApps.stable.whatsApp
    pkgs.webApps.stable.youtube
  ];
}
