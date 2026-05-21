{
  config,
  lib,
  pkgs,
  pkgs-unstable,
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

  # Gemini CLI Work configurations
  # Restrict "glob" and "search_file_content" tools
  deniedTools = [
    "glob"
    "search_file_content"
  ];

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

  workPolicies = {
    rule =
      (builtins.map (toolName: mkRule toolName "deny" 100) deniedTools)
      ++ (mkRunShellCommandRules "allow" 100 allowedShellCommands);
  };

  workPolicyFile = (pkgs.formats.toml { }).generate "nix.toml" workPolicies;

  jjCommitMsgTmpDir = "${config.home.homeDirectory}/.gemini/tmp/jj-commit-msg";

  workSettings = {
    context.includeDirectories = [ jjCommitMsgTmpDir ];
    context.fileFiltering.enableRecursiveFileSearch = false;
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
    ui.useAlternateBuffer = false;
    general.enableAutoUpdate = true;
    privacy.usageStatisticsEnabled = true;
    advanced.autoConfigureMemory = true;
    experimental = { };
    general.plan.enabled = true;
    general.enableNotifications = true;
    agents.overrides = { };
    general.defaultApprovalMode = "default";
    tools.disableLLMCorrection = false;
  };
  workSettingsFile = (pkgs.formats.json { }).generate "gemini-cli-settings.json" workSettings;

  # Work-specific gcert helpers
  minHours = 10;
  minSeconds = minHours * 60 * 60;
  ensureGcert = pkgs.writeShellScriptBin "ensure-gcert" ''
    if ! output=$(/usr/bin/gcertstatus --format=simple 2>&1) || \
      ! echo "$output" | ${pkgs.gawk}/bin/awk -F: '/^(loas2|corp\/normal):/ && $2 < '${toString minSeconds}' {exit 1}'; then
      echo "--- Certificate missing or expiring (<${toString minHours}h). Refreshing... ---"
      /usr/bin/gcert
    fi
  '';
  sshWrapper = pkgs.writeShellScriptBin "ssh" ''
    ${ensureGcert}/bin/ensure-gcert
    exec /usr/bin/ssh "$@"
  '';
in
{
  imports = [
    ./common.nix
    ../programs/google-chrome-autostart.nix
  ];

  config = {
    # 1. Ask helper wrapper for Gemini, gcert helpers, and wrapped ssh client
    home.packages = [
      (pkgs.writeShellScriptBin "ask" ''
        exec ask-gemini "$@"
      '')
      ensureGcert
      sshWrapper
    ];

    # 2. Ptyxis workstation terminal profiles and defaults
    dconf.settings = {
      "org/gnome/Ptyxis" = {
        default-profile-uuid = lib.mkForce workWorkstationUuid;
        profile-uuids = lib.mkForce [
          defaultProfileUuid
          workWorkstationUuid
        ];
      };

      "org/gnome/Ptyxis/Profiles/${defaultProfileUuid}" = lib.mkForce (
        defaultProfile // defaultProfileWorkLaptopOverride
      );

      "org/gnome/Ptyxis/Profiles/${workWorkstationUuid}" = workWorkstationProfile;
    };

    # 3. Work-specific Gemini CLI policies & settings overrides
    _geminiPolicyFile = lib.mkForce workPolicyFile;

    anti-drift.files = {
      ".gemini/settings.json" = lib.mkForce {
        source = workSettingsFile;
        json = true;
      };
      ".gemini/policies/nix.toml" = lib.mkForce {
        source = workPolicyFile;
      };
    };

    # 4. Work-specific Jujutsu settings
    programs.jujutsu.settings.aliases = {
      mv = [
        "piper"
        "rename"
      ];
    };

    # 5. Work-specific SSH match blocks
    programs.ssh.matchBlocks = {
      "*.corp.google.com" = {
        forwardAgent = true;
        identityAgent = null;
      };
      "ws" = {
        hostname = "dan.nyc.corp.google.com";
      };
    };

    # 6. Work ssh-askpass desktop entry
    xdg.desktopEntries.ssh-askpass = {
      name = "ssh-askpass";
      type = "Application";
      exec = "/usr/bin/ssh-askpass";
      terminal = false;
    };

    # 7. Work fish shell interactive init (checks gcert status)
    programs.fish.interactiveShellInit = ''
      set -l gcert_check_file "/tmp/gcert_check_$USER"
      if not test -e "$gcert_check_file"; or test -n "$(find "$gcert_check_file" -mmin +60 2>/dev/null)"
        ${ensureGcert}/bin/ensure-gcert
        touch "$gcert_check_file"
      end
    '';
  };
}
