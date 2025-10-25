{
  config,
  lib,
  pkgs,
  ...
}:

let
  profileUuid = "C0FFEE-C0DE-FEED-FACE-AC1DDEADBEEF";
in

{
  home.packages = with pkgs; [
    (config.lib.nixGL.wrap ptyxis)
  ];

  dconf.settings = {
    "org/gnome/Ptyxis/Shortcuts" = {
      close-tab = "<Control>w";
      close-window = "";
      copy-clipboard = "<Control>c";
      new-tab = "<Control>t";
      new-window = "<Shift><Control>n";
      paste-clipboard = "<Control>v";
      reset-and-clear = "'<Shift><Control>r'";
      search = "<Shift><Control>f";
      select-all = "<Control>a";
    };

    "org/gnome/Ptyxis" = {
      default-profile-uuid = profileUuid;
      profile-uuids = [ profileUuid ];
      use-system-font = true;
    };

    "org/gnome/Ptyxis/Profiles/${profileUuid}" = {
      label = "The Coffee Coder";
      opacity = lib.gvariant.mkDouble 0.9;
      palette = "Japanesque";
      use-custom-command = true;
      custom-command = "/usr/bin/bash";
      cell-height-scale = 1.0;
    };
  };
}
