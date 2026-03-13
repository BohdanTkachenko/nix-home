{
  config,
  lib,
  pkgs,
  ...
}:
let
  deniedTools =
    [ ]
    ++ (lib.optional config.my.google.enable [
      "glob"
      "search_file_content"
    ]);

  allowedShellCommands = {
    # Fully allow these commands
    cat = null;
    echo = null;
    eza = null;
    tee = null;
    ls = null;
    mktemp = null;

    # Only allow certain sub-commands for these commands
    jj = [
      "describe"
      "describe-to-file"
      "describe-from-file"
      "diff"
      "log"
      "show"
      "status"
    ];
  };

  mkRule = toolName: decision: priority: {
    inherit toolName decision priority;
  };

  mkRunShellCommandRule =
    decision: priority: command: subCommands:
    (
      mkRule "run_shell_command" decision priority
      // (
        if subCommands == null then
          {
            commandPrefix = command;
          }
        else
          {
            commandRegex = "${command} (${builtins.concatStringsSep "|" subCommands})";
          }
      )
    );

  mkRunShellCommandRules =
    decision: priority: commands:
    let
      fullCommands = lib.attrNames (lib.attrsets.filterAttrs (k: v: v == null) commands);
      commandsWithSubCommands = lib.attrsets.filterAttrs (k: v: v != null) commands;
    in
    (lib.optional (builtins.length fullCommands > 0) (
      mkRunShellCommandRule decision priority fullCommands null
    ))
    ++ (lib.attrsets.mapAttrsToList (
      cmd: subCmds: mkRunShellCommandRule decision priority cmd subCmds
    ) commandsWithSubCommands);

  policies = {
    rule =
      (builtins.map (toolName: mkRule toolName "deny" 100) deniedTools)
      ++ (mkRunShellCommandRules "allow" 100 allowedShellCommands);
  };

  policyFile = (pkgs.formats.toml { }).generate "nix.toml" policies;

  jjCommitMsgTmpDir = "${config.home.homeDirectory}/.gemini/tmp/jj-commit-msg";

  # Schema: https://raw.githubusercontent.com/google-gemini/gemini-cli/refs/heads/main/packages/cli/src/config/settingsSchema.ts
  settings =
    lib.recursiveUpdate
      {
        context.includeDirectories = [ jjCommitMsgTmpDir ];
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
        ui.footer.hideContextPercentage = false;
        ui.footer.hideSandboxStatus = true;
        ui.showStatusInTitle = true;
        ui.useAlternateBuffer = true;
        general.enableAutoUpdate = false;
        privacy.usageStatisticsEnabled = false;
        advanced.autoConfigureMemory = true;
        experimental.plan = true;
        general.defaultApprovalMode = "default";
        tools.disableLLMCorrection = false;
      }
      (
        lib.optionalAttrs config.my.google.enable {
          general.enableAutoUpdate = true;
          privacy.usageStatisticsEnabled = true;
          context.fileFiltering.enableRecursiveFileSearch = false;
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

  config.home.activation = {
    init = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p ${jjCommitMsgTmpDir}
    '';
  };

  # The flake sets a default GEMINI_MODEL env var which takes precedence over
  # the config file, making it impossible to change the model via settings.
  # Setting this to empty allows Gemini CLI to use the config file instead.
  config.programs.gemini-cli.defaultModel = "";

  config.anti-drift.files = {
    ".gemini/settings.json" = {
      source = settingsFile;
      json = true;
    };
    ".gemini/policies/nix.toml" = {
      source = policyFile;
    };
  };

}
