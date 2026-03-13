{ config, lib, ... }:
{
  options.my = {
    google.enable = lib.mkEnableOption "Google corp environment";

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

    ai.gemini.extraFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Extra flags to pass to the gemini CLI wrapper";
    };

    vscode.useFHS = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to use the FHS-wrapped VS Code package";
    };

    terminal.ptyxis.workstationProfile.enable = lib.mkEnableOption "Ptyxis SSH workstation profile";

    secrets.sops.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable sops secret management";
    };
  };
}
