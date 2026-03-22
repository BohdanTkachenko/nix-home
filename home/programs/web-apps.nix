{
  config,
  pkgs,
  ...
}:
{
  home.packages = with pkgs.webApps; [
    # Work and personal
    gmail
    googleCalendar
    googleChat
    googleGemini
    googleMeet
  ];
}
