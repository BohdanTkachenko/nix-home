{
  pkgs,
  isWork ? false,
  ...
}:
let
  personalPkg = if isWork then pkgs.webApps.beta else pkgs.webApps.stable;
in
{
  home.packages = [
    # Work and personal
    pkgs.webApps.stable.gmail
    pkgs.webApps.stable.googleCalendar
    pkgs.webApps.stable.googleChat
    pkgs.webApps.stable.googleGemini
    pkgs.webApps.stable.googleMeet

    # Personal only
    personalPkg.googleGemini
    personalPkg.googleMessages
    personalPkg.whatsApp
  ];
}
