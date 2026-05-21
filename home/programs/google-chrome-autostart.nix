{
  config,
  lib,
  pkgs,
  ...
}:
{
  systemd.user.paths.fix-google-chrome-stable-autostart = {
    Unit = {
      Description = "Watch ~/.config/autostart for Google Chrome autostart shortcut changes";
    };
    Path = {
      PathChanged = "%h/.config/autostart/";
    };
    Install = {
      WantedBy = [ "paths.target" ];
    };
  };

  systemd.user.services.fix-google-chrome-stable-autostart = {
    Unit = {
      Description = "Fix Google Chrome autostart shortcut path";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.python3}/bin/python3 ${../../overlays/fix-chrome-autostart.py} /opt/google/chrome/google-chrome google-chrome-stable";
    };
  };
}
