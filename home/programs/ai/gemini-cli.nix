{
  config,
  lib,
  pkgs,
  pkgs-unstable,
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
    awk = null;
    basename = null;
    cat = null;
    curl = null;
    cut = null;
    date = null;
    diff = null;
    dig = null;
    dirname = null;
    du = null;
    echo = null;
    env = null;
    eza = null;
    fd = null;
    file = null;
    find = null;
    grep = null;
    head = null;
    host = null;
    jq = null;
    ls = null;
    man = null;
    md5sum = null;
    mktemp = null;
    nslookup = null;
    printenv = null;
    rg = null;
    sed = null;
    sha256sum = null;
    sort = null;
    stat = null;
    tail = null;
    tee = null;
    tokei = null;
    tr = null;
    tree = null;
    uname = null;
    uniq = null;
    wc = null;
    wget = null;
    which = null;
    yq = null;

    # Only allow certain sub-commands for these commands
    cargo = [
      "bench"
      "build"
      "check"
      "clippy"
      "doc"
      "metadata"
      "read-manifest"
      "search"
      "test"
      "tree"
      "verify-project"
    ];
    go = [
      "build"
      "doc"
      "env"
      "list"
      "mod graph"
      "mod verify"
      "test"
      "version"
      "vet"
    ];
    gh = [
      "api"
      "issue list"
      "issue status"
      "issue view"
      "pr checks"
      "pr diff"
      "pr list"
      "pr status"
      "pr view"
      "repo list"
      "repo view"
      "run list"
      "run view"
      "search"
      "status"
    ];
    git = [
      "blame"
      "diff"
      "log"
      "show"
      "status"
    ];
    npm = [
      "audit"
      "explain"
      "list"
      "outdated"
      "run"
      "search"
      "test"
      "view"
    ];
    npx = null;
    nix = [
      "build"
      "derivation show"
      "eval"
      "flake"
      "hash"
      "path-info"
      "search"
      "store"
      "why-depends"
    ];
    nix-instantiate = [ "--eval" ];
    nix-store = [
      "--query"
      "-q"
    ];
    nixos-option = null;
    systemctl = [
      "cat"
      "is-active"
      "is-enabled"
      "list-dependencies"
      "list-timers"
      "list-unit-files"
      "list-units"
      "show"
      "status"
    ];
    journalctl = null;
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
  config.programs.gemini-cli.package = pkgs-unstable.gemini-cli;

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
