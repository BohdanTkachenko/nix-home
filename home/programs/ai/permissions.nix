{ config, lib, ... }:
let
  # ── Master permission definitions (tool-agnostic) ──────────────────────

  # Shell commands: null = allow all subcommands, list = specific subcommands only.
  # This is the single source of truth shared by Claude Code, Antigravity IDE,
  # and Gemini CLI.
  commands = {
    # General CLI
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
    readlink = null;
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

    # Cargo (read-only / build)
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

    # Go (read-only / build)
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

    # GitHub CLI (read-only)
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

    # Git (read-only)
    git = [
      "blame"
      "diff"
      "log"
      "show"
      "status"
    ];

    # npm (read-only / build)
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

    # Jujutsu (read-only)
    jj = [
      "describe"
      "describe-to-file"
      "describe-from-file"
      "diff"
      "log"
      "show"
      "status"
      "workspace list"
      "workspace root"
    ];

    # systemctl (read-only)
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

    # Nix (read-only)
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
    nix-prefetch-url = null;
    nix-hash = null;
    nixos-option = null;
  };

  # File system read access patterns
  readPaths = [
    "/home/dan/.cargo"
    "/nix/store"
  ];

  # Web access
  web = {
    search = true;
    fetch = true;
    urls = [ "raw.githubusercontent.com" ];
  };

  # MCP tool permissions (read-only Plane tools)
  mcpTools = [
    "plane.get_me"
    "plane.get_project_features"
    "plane.get_project_members"
    "plane.get_project_worklog_summary"
    "plane.get_workspace_features"
    "plane.get_workspace_members"
    "plane.list_archived_cycles"
    "plane.list_archived_modules"
    "plane.list_cycle_work_items"
    "plane.list_cycles"
    "plane.list_epics"
    "plane.list_initiatives"
    "plane.list_intake_work_items"
    "plane.list_labels"
    "plane.list_milestone_work_items"
    "plane.list_milestones"
    "plane.list_module_work_items"
    "plane.list_modules"
    "plane.list_projects"
    "plane.list_states"
    "plane.list_work_item_activities"
    "plane.list_work_item_comments"
    "plane.list_work_item_links"
    "plane.list_work_item_properties"
    "plane.list_work_item_relations"
    "plane.list_work_item_types"
    "plane.list_work_items"
    "plane.list_work_logs"
    "plane.retrieve_cycle"
    "plane.retrieve_epic"
    "plane.retrieve_initiative"
    "plane.retrieve_intake_work_item"
    "plane.retrieve_label"
    "plane.retrieve_milestone"
    "plane.retrieve_module"
    "plane.retrieve_project"
    "plane.retrieve_project_page"
    "plane.retrieve_state"
    "plane.retrieve_work_item"
    "plane.retrieve_work_item_activity"
    "plane.retrieve_work_item_by_identifier"
    "plane.retrieve_work_item_comment"
    "plane.retrieve_work_item_link"
    "plane.retrieve_work_item_property"
    "plane.retrieve_work_item_type"
    "plane.retrieve_workspace_page"
    "plane.search_work_items"
  ];

  # ── Formatters ─────────────────────────────────────────────────────────

  # Expand the commands map into a flat list using a formatting function
  expandCommands = formatFull: formatSub:
    lib.concatLists (lib.mapAttrsToList (cmd: subCmds:
      if subCmds == null then
        [ (formatFull cmd) ]
      else
        builtins.map (sub: formatSub cmd sub) subCmds
    ) commands);

  # Claude Code: "Bash(cmd:*)" / "Bash(cmd sub:*)"
  claudeCommands = expandCommands
    (cmd: "Bash(${cmd}:*)")
    (cmd: sub: "Bash(${cmd} ${sub}:*)");

  claudeReadPaths = lib.concatMap (p:
    let escaped = builtins.replaceStrings [ "/" "." ] [ "//" "." ] p; in
    [
      "Read(${escaped}//**)"
      "Grep(${escaped}//**)"
      "Glob(${escaped}//**)"
    ]
  ) readPaths;

  claudeWeb =
    (lib.optional web.search "Search")
    ++ (lib.optional web.search "WebSearch")
    ++ (lib.optional web.fetch "WebFetch");

  claudeMcpTools = builtins.map (t:
    builtins.replaceStrings [ "." ] [ "__" ] "mcp__${t}"
  ) mcpTools;

  # Antigravity IDE: "command(cmd)" / "command(cmd sub)"
  antigravityCommands = expandCommands
    (cmd: "command(${cmd})")
    (cmd: sub: "command(${cmd} ${sub})");

  antigravityWeb = lib.concatMap (url: [ "read_url(${url})" ]) web.urls;

in
{
  lib.permissions = {
    # Raw commands map (for Gemini CLI's existing TOML policy generator)
    inherit commands;

    # Fully formatted permission lists
    forClaude =
      claudeWeb
      ++ claudeReadPaths
      ++ [ "Grep" "Glob" ]
      ++ claudeCommands
      ++ claudeMcpTools;

    forAntigravity =
      antigravityWeb
      ++ [ "command(cd)" ]
      ++ antigravityCommands;
  };
}
