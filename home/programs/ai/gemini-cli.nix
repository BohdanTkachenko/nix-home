{
  config,
  isWork,
  isWorkPC,
  lib,
  pkgs,
  ...
}:
let
  allowedCommands = [
    "cat"
    "echo"
    "eza"
    "tee"
    "ls"
    "mktemp"
  ];
  allowedSubcommands = {
    jj = [
      "describe"
      "diff"
      "log"
      "show"
      "status"
    ];
  };

  policyFile =
    let
      toolName = "run_shell_command";
      decision = "allow";
      priority = 100;
    in
    (pkgs.formats.toml { }).generate "nix.toml" {
      rule = [
        {
          inherit toolName decision priority;
          commandPrefix = allowedCommands ++ [ config._jjCommitMsg ];
        }
      ]
      ++ (lib.attrsets.mapAttrsToList (command: subcommands: {
        inherit toolName decision priority;
        commandRegex = "${command} (${builtins.concatStringsSep "|" subcommands})";
      }) allowedSubcommands);
    };
in
{
  imports = [
    ./jj-commit-command.nix
  ];

  options._geminiPolicyFile = lib.mkOption {
    type = lib.types.path;
    internal = true;
    description = "Path to generated Gemini CLI policy file for testing";
  };

  config._geminiPolicyFile = policyFile;

  config.programs.gemini-cli.enable = true;

  # Flake has a default value for this option and it is persisting it into
  # sessionVariables which requires reboot or re-login to change it.
  # For Gemini CLI this env variable takes precedence over a config file.
  # This makes it impossible to specify the model using config.
  # Setting this to an empty value allows Gemini CLI to look into the config
  # instead.
  config.programs.gemini-cli.defaultModel = "";

  config.programs.gemini-cli.settings =
    lib.recursiveUpdate
      {
        context.includeDirectories = ["${config.home.homeDirectory}/.gemini/tmp/jj-commit-msg"];
        context.fileFiltering.enableRecursiveFileSearch = true;
        general.preferredEditor = "vim";
        general.previewFeatures = true;
        general.sessionRetention.enabled = true;
        general.sessionRetention.warningAcknowledged = true;
        general.sessionRetention.maxAge = "120d";
        ide.enabled = true;
        ide.hasSeenNudge = true;
        security.auth.selectedType = "oauth-personal";
        security.enablePermanentToolApproval = true;
        tools.autoAccept = true;
        tools.shell.pager = lib.getExe pkgs.bat;
        tools.shell.showColor = true;
        ui.theme = "Atom One";
      }
      (
        lib.optionalAttrs (!isWork) {
          general.disableAutoUpdate = true;
          general.disableUpdateNags = true;
          privacy.usageStatisticsEnabled = false;
        }
      );

  # Gemini CLI ignores symlinks. As a workaround, copy the file instead.
  config.home.activation.copyGeminiPolicy = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p $HOME/.gemini/policies
    run cp -f "${policyFile}" "$HOME/.gemini/policies/nix.toml"
    run chmod 644 "$HOME/.gemini/policies/nix.toml"
  '';

}
