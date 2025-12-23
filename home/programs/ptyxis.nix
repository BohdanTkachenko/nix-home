{
  config,
  lib,
  pkgs,
  isWork,
  isWorkLaptop,
  ...
}:

let
  defaultProfileUuid = "C0FFEE-C0DE-FEED-FACE-AC1DDEADBEEF";
  defaultProfile = {
    label = "The Coffee Coder";
    palette = "Japanesque";
    opacity = lib.gvariant.mkDouble 0.9;
    cell-height-scale = 1.0;
    use-custom-command = false;
  };

  workWorkstationUuid = "60061E-CAFE-F00D-FA57-0FF1CEACCE55";
  workWorkstationProfile = defaultProfile // {
    label = "The Free Food Eater";
    use-custom-command = true;
    custom-command = "ssh ws";
  };
in

{
  registry.debian.packages = [ "ptyxis" ];
  home.packages = lib.mkIf (!isWork) (
    with pkgs;
    [
      ptyxis
    ]
  );

  dconf.settings = {
    "org/gnome/Ptyxis/Shortcuts" = {
      close-tab = "<Control>w";
      close-window = "";
      copy-clipboard = "<Control>c";
      new-tab = "<Control>t";
      new-window = "<Shift><Control>n";
      paste-clipboard = "<Control>v";
      reset-and-clear = "<Shift><Control>r";
      search = "<Shift><Control>f";
      select-all = "<Control>a";
    };

    "org/gnome/Ptyxis" = {
      default-profile-uuid = defaultProfileUuid;
      profile-uuids = [ defaultProfileUuid ] ++ (if isWorkLaptop then [ workWorkstationUuid ] else [ ]);
      use-system-font = true;
    };

    "org/gnome/Ptyxis/Profiles/${defaultProfileUuid}" = defaultProfile;
  }
  // (
    if isWorkLaptop then
      {
        "org/gnome/Ptyxis/Profiles/${workWorkstationUuid}" = workWorkstationProfile;
      }
    else
      { }
  );
}
