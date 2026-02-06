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
    pkgs.webApps.stable.googleGemini
    pkgs.webApps.stable.googleMeet

    # Personal only
    personalPkg.facebookMessenger
    # personalPkg.googleGemini
    # personalPkg.googleMeet
    personalPkg.googleMessages
    personalPkg.whatsApp
    personalPkg.youtube
  ];
}
