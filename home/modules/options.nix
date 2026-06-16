{ config, lib, ... }:
{
  options.my = {
    gui.enable = lib.mkEnableOption "graphical session: desktop apps, GNOME integration, and I/O peripheral helpers (xremap, etc.)";

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

    google-chrome.mkWrapper = lib.mkOption {
      type = with lib.types; functionTo (functionTo package);
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

    lemonade = {
      client.enable = lib.mkEnableOption "lemonade client: forward URL-opens (xdg-open/$BROWSER) and clipboard from this headless host to a lemonade server on the local machine over an SSH reverse tunnel";
      server.enable = lib.mkEnableOption "lemonade server: apply URL-opens and clipboard received from remote hosts to this machine's browser and clipboard, and add the SSH reverse tunnel out to workbench";
    };
  };
}
