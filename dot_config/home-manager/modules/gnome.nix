{ lib, ... }:

let
  profileUuid = "C0FFEE-C0DE-FEED-FACE-AC1DDEADBEEF";
in

{
  dconf.settings = {
    "org/gnome/desktop/wm/keybindings" = {
      close = [ "<Shift><Control>q" ];
      switch-applications = [ "<Control>Tab" ];
      switch-applications-backward = [ "<Shift><Control>Tab" ];
      switch-group = [ "<Control>grave" ];
      switch-group-backward = [ "<Shift><Control>grave" ];
    };

    "org/gnome/settings-daemon/plugins/media-keys" = {
      next = [ "AudioNext" ];
      play = [ "AudioPlay" ];
      previous = [ "AudioPrev" ];
    };

    "org/gnome/Ptyxis/Shortcuts" = {
      close-tab = "<Control>w";
      close-window = "";
      copy-clipboard = "<Control>c";
      new-tab = "<Control>t";
      new-window = "<Control>n";
      paste-clipboard = "<Control>v";
      search = "<Control>f";
      select-all = "<Control>a";
    };

    "org/gnome/Ptyxis" = {
      default-profile-uuid = profileUuid;
      profile-uuids = [ profileUuid ];
    };

    "org/gnome/Ptyxis/Profiles/${profileUuid}" = {
      label = "The Coffee Coder";
      opacity = lib.gvariant.mkDouble 0.9;
      palette = "Japanesque";
    };
  };
}
