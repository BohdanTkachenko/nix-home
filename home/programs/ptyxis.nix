{
  config,
  lib,
  pkgs,
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

  # Workaround for a bug: when connected by SSH and trying to open a default
  # profile, it might get stuck.
  restrictedDirs = [
    "/google"
  ];
  restrictedPattern = "^(" + (builtins.concatStringsSep "|" restrictedDirs) + ")";
  safePwd = pkgs.writeShellScriptBin "safe-pwd" ''
    pattern="${restrictedPattern}"
    if [[ "$PWD" =~ $pattern ]] || \
       [[ "$(readlink "$PWD" 2>/dev/null)" =~ $pattern ]] || \
       [[ ! -d "$PWD" ]] || \
       [[ "$(realpath "$PWD" 2>/dev/null)" =~ $pattern ]]; then
      cd "$HOME"
    fi
    exec fish
  '';
  defaultProfileWorkLaptopOverride = {
    use-custom-command = true;
    custom-command = "${safePwd}/bin/safe-pwd";
    preserve-directory = "always";
  };

  workWorkstationUuid = "60061E-CAFE-F00D-FA57-0FF1CEACCE55";
  sshWsCd = pkgs.writeShellScriptBin "ssh-ws-cd" ''
    target="''${PWD/#\/home/\/usr\/local\/google\/home}"
    exec ssh -t ws "fish -C '
      if test -d \"$target\"
         and not string match -q \"/tmp*\" \"$target\"
         cd \"$target\"
      end
    '"
  '';
  workWorkstationProfile = defaultProfile // {
    label = "The Free Food Eater";
    use-custom-command = true;
    custom-command = "${sshWsCd}/bin/ssh-ws-cd";
    preserve-directory = "always";
  };
in

{
  home.packages = lib.mkIf (!config.my.google.enable) (
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
      default-profile-uuid =
        if config.my.terminal.ptyxis.workstationProfile.enable then
          workWorkstationUuid
        else
          defaultProfileUuid;
      profile-uuids = [
        defaultProfileUuid
      ]
      ++ (if config.my.terminal.ptyxis.workstationProfile.enable then [ workWorkstationUuid ] else [ ]);
      use-system-font = true;
    };

    "org/gnome/Ptyxis/Profiles/${defaultProfileUuid}" =
      defaultProfile
      // (
        if config.my.terminal.ptyxis.workstationProfile.enable then
          defaultProfileWorkLaptopOverride
        else
          { }
      );
  }
  // (
    if config.my.terminal.ptyxis.workstationProfile.enable then
      {
        "org/gnome/Ptyxis/Profiles/${workWorkstationUuid}" = workWorkstationProfile;
      }
    else
      { }
  );
}
