{ pkgs, ... }:

let
  xremapPackage = pkgs.xremap.  gnome;
in
{
  home.packages = [ pkgs.wev xremapPackage ];

  xdg.configFile."xremap.yml" = {
    text = ''
      modmap:
        - name: Swap LCTRL and LWIN
          devices:
            - name: "AT Translated Set 2 keyboard"
          remap:
            CapsLock: Backspace
            Alt_L: Control_L
            Super_L: Alt_L
            Control_L: Super_L
    '';
  };

  systemd.user.services.xremap = {
    Unit = {
      Description = "xremap input remapper";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${xremapPackage}/bin/xremap --watch %h/.config/xremap.yml";
      Restart = "always";
      RestartSec = "1s";
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}