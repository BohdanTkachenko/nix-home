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
  settings = lib.recursiveUpdate
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
  settingsFile = (pkgs.formats.json { }).generate "gemini-cli-settings.json" settings;
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

  # The flake sets a default GEMINI_MODEL env var which takes precedence over
  # the config file, making it impossible to change the model via settings.
  # Setting this to empty allows Gemini CLI to use the config file instead.
  config.programs.gemini-cli.defaultModel = "";

  config.anti-drift.files = {
    ".gemini/settings.json" = { source = settingsFile; json = true; };
    ".gemini/policies/nix.toml" = { source = policyFile; };
  };

}
