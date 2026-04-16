{ config, lib, ... }:
{
  options.my = {
    hardware.lenovo.thinkpad = {
      enable = lib.mkEnableOption "Enable Lenovo Thinkpad tweaks";

      model = lib.mkOption {
        type =
          with lib.types;
          nullOr (enum [
            "x1-carbon-gen12"
            "z16-gen1"
          ]);
        default = null;
        description = "Lenovo Thinkpad model";
      };
    };

    environment = lib.mkOption {
      type = lib.types.enum [
        "personal"
        "work"
      ];
      description = "Environment type for this machine";
    };

    google.enable = lib.mkEnableOption "Google corp environment";

    google-chrome.mkWrapper = lib.mkOption {
      type = lib.types.anything;
      default = pkg: flags: pkg.override { commandLineArgs = flags; };
      description = "Function to wrap the Google Chrome package with custom flags.";
    };

    identity.email = lib.mkOption {
      type = lib.types.str;
      default = "bohdan@tkachenko.dev";
      description = "Primary email address for git/jj config";
    };

    identity.name = lib.mkOption {
      type = lib.types.str;
      default = "Bohdan Tkachenko";
      description = "Full name for git/jj config";
    };

    vscode.useFHS = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to use the FHS-wrapped VS Code package";
    };

    terminal.ptyxis.workstationProfile.enable = lib.mkEnableOption "Ptyxis SSH workstation profile";

    winapps.enable = lib.mkEnableOption "WinApps Windows VM";

    screenshotPathClipboard.enable = lib.mkEnableOption "Replace GNOME screenshot image-on-clipboard with its file path (so Claude Code in a terminal can read it on paste)";

    direnv-instant.enable = lib.mkEnableOption "direnv-instant async direnv daemon";

    secrets.sops.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable sops secret management";
    };
  };
}
