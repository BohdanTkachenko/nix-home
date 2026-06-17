{
  config,
  lib,
  pkgs,
  pkgs-master,
  ...
}:

let
  pinToCCD1 = import ../../../lib/pin-to-ccd1.nix { inherit pkgs; };

  # On the aarch64 workbench, make Claude believe it has 20 logical CPUs so its
  # `min(16, cores-2)` workflow concurrency cap lifts from 2 to 16. No-op on the
  # x86_64 desktops. See lib/fake-cores.nix.
  fakeCores = import ../../../lib/fake-cores.nix { inherit pkgs; };

  # MCP servers are declared with `${VAR}` placeholders for secrets. Claude
  # Code natively expands these from the process env at load time (see the
  # `Sy6` function in cli.js), the same way VS Code's mcp.json supports
  # `${env:FOO}` and Gemini CLI supports `$VAR`/`${VAR}`. The config file
  # itself contains no secrets and is rendered to ~/.claude/mcp.json via
  # anti-drift; the wrapper below exports the env vars from sops-rendered
  # secret files just before exec, then passes --mcp-config to claude.
  # The MCP config carries env-var references (${VAR}); Claude Code expands them
  # at load time from the process env, which the wrapper below exports just
  # before exec. So the file itself holds no secrets.
  mcpFile = (pkgs.formats.json { }).generate "claude-mcp.json" {
    mcpServers = config.lib.mcp.makeMcpServers {
      isClaude = true;
      secrets = {
        githubPat = "\${GITHUB_PERSONAL_ACCESS_TOKEN}";
        gitlabPat = "\${GITLAB_PERSONAL_ACCESS_TOKEN}";
        planeApiKey = "\${PLANE_API_KEY}";
        planeWorkspaceSlug = "\${PLANE_WORKSPACE_SLUG}";
        claudeHaMcpUrl = "\${CLAUDE_HA_MCP_URL}";
      };
    };
  };

  # The secret files live in config.my.ai.secretsDir (sops-decrypted by the
  # private overlay; null on a public build → no token exports). Each `--run`
  # snippet exports VAR from its file, with `2>/dev/null || true` so a missing
  # secret doesn't abort the wrapper (makeWrapper sets `bash -e`).
  secretsDir = config.my.ai.secretsDir;
  exportSecret =
    file: var: ''export ${var}="$(cat "${secretsDir}/${file}" 2>/dev/null || true)"'';
  wrapArgs = [
    ''--set SUDO_ASKPASS "${pkgs.seahorse}/libexec/seahorse/ssh-askpass"''
    "--set UV_PYTHON_PREFERENCE only-system"
    "--set CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN 1"
    ''--prefix PATH : "${pkgs.python3}/bin"''
    # The --mcp-config path is single-quoted so nothing expands at build time;
    # bash expands $HOME at exec time when the wrapper script runs.
    "--add-flags '--mcp-config=\"\$HOME/.claude/mcp.json\"'"
  ]
  ++ lib.optionals (secretsDir != null) [
    "--run '${exportSecret "github-pat" "GITHUB_PERSONAL_ACCESS_TOKEN"}'"
    "--run '${exportSecret "gitlab-pat" "GITLAB_PERSONAL_ACCESS_TOKEN"}'"
    "--run '${exportSecret "plane-api-key" "PLANE_API_KEY"}'"
    "--run '${exportSecret "plane-workspace-slug" "PLANE_WORKSPACE_SLUG"}'"
    "--run '${exportSecret "claude-ha-mcp-url" "CLAUDE_HA_MCP_URL"}'"
  ];

  claude-code-wrapped = pkgs.symlinkJoin {
    name = "claude-code-wrapped";
    paths = [ pkgs-master.claude-code ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/claude \
        ${lib.concatStringsSep " \\\n        " wrapArgs}
    '';
  };

  ticktick-mcp-server = pkgs.buildNpmPackage {
    pname = "ticktick-mcp-server";
    version = "1.0.0-unstable";
    src = pkgs.fetchFromGitHub {
      owner = "liadgez";
      repo = "ticktick-mcp-server";
      rev = "bb4e76f78542c6a64c929e2624952889d859e78e";
      hash = "sha256-26VReX/Qw0lAsq08kah+9IAZr77bhw+g5t4TCosCgM4=";
    };
    npmDepsHash = "sha256-+T6k5JhaqQI0Fqu8I7ftYfG1+4QFeqBzfuPSs3PIop8=";
    dontBuild = true;
    meta.mainProgram = "ticktick-mcp-server";
    postInstall = ''
      mkdir -p $out/bin
      cat > $out/bin/ticktick-mcp-server <<'SCRIPT'
      #!/usr/bin/env node
      import("$out/lib/node_modules/ticktick-mcp-docker/src/index.js");
      SCRIPT
      chmod +x $out/bin/ticktick-mcp-server
    '';
  };

  jj = "${pkgs.jujutsu}/bin/jj";

  statusline-script = pkgs.writeScriptBin "claude-statusline" ''
    #!/usr/bin/env -S ${pkgs.nushell}/bin/nu --stdin

    def dir [cwd: string] {
      if $cwd == "" { return "" }
      let display = $cwd | str replace $env.HOME "~"
      let label = if ($display | split row "/" | length) <= 2 { $display } else {
        $display | split row "/" | last 2 | str join "/"
      }
      let esc = char -u "1b"
      let dir_link = $"($esc)]8;;file://($cwd)($esc)\\($label)($esc)]8;;($esc)\\"
      let code_link = $"($esc)]8;;vscode://file($cwd)?windowId=_blank($esc)\\($esc)]8;;($esc)\\"
      $"($dir_link) ($code_link)"
    }

    def jj-info [cwd: string] {
      if $cwd == "" { return "" }
      let root = do { ${jj} --ignore-working-copy --no-pager root --quiet -R $cwd } | complete
      if $root.exit_code != 0 { return "" }
      let out = do {
        ${jj} log --ignore-working-copy --no-pager -r @ --no-graph --color always --limit 1 -R $cwd --template '
          separate(" ",
            change_id.shortest(4),
            bookmarks,
            concat(
              if(conflict, "󰞇"),
              if(divergent, "󰃻"),
              if(hidden, ""),
              if(immutable, ""),
            ) ++ raw_escape_sequence("\x1b[0m"),
            if(description, "(" ++ description.first_line().substr(0, 40) ++ ")"),
          )
        '
      } | complete
      let trimmed = $out.stdout | str trim
      if $out.exit_code == 0 and $trimmed != "" { $" ($trimmed)" } else { "" }
    }

    def fmt-pct [label: string, val: any] {
      if $val == null { return "" }
      let pct = $val | math round
      let esc = char -u "1b"
      let color = if $pct <= 50 { "32" } else if $pct <= 75 { "33" } else { "31" }
      $" ($esc)[($color)m($label):($pct)%($esc)[0m"
    }

    def ctx-colored [val: any] {
      if $val == null { return "" }
      let pct = $val | math round
      let esc = char -u "1b"
      let color = if $pct >= 50 { "32" } else if $pct >= 25 { "33" } else { "31" }
      $" ($esc)[($color)mctx:($pct)%($esc)[0m"
    }

    def main [] {
      let input = $in | from json
      let cwd = $input | get -o cwd | default ""
      let model = $input | get -o model.display_name | default ""
      let model_part = if $model != "" { $"  ($model)" } else { "" }
      let ctx = ctx-colored ($input | get -o context_window.remaining_percentage)
      let five = fmt-pct "5h" ($input | get -o rate_limits.five_hour.used_percentage)
      let week = fmt-pct "7d" ($input | get -o rate_limits.seven_day.used_percentage)

      print -n ([(dir $cwd) (jj-info $cwd) $model_part $ctx $five $week] | str join "" | str trim)
    }
  '';

  # User-facing Claude Code settings, rendered to ~/.claude/settings.json via
  # anti-drift (matching the pattern used for vscode/gemini-cli). The
  # statusLine command is a PATH-relative name (not an absolute store path)
  # so it stays drift-stable across rebuilds — claude-statusline lands on
  # PATH via home.packages below.
  userSettings = {
    "$schema" = "https://json.schemastore.org/claude-code-settings.json";

    agentPushNotifEnabled = true;
    inputNeededNotifEnabled = true;
    model = "opus[1m]";
    cleanupPeriodDays = 3650;
    effortLevel = "high";
    theme = "dark";
    enabledPlugins = {
      "gopls-lsp@claude-plugins-official" = true;
      "rust-analyzer-lsp@claude-plugins-official" = true;
    };
    statusLine = {
      type = "command";
      command = "claude-statusline";
    };
    voiceEnabled = true;
    remoteControlAtStartup = true;
    skipAutoPermissionPrompt = true;
    skipWorkflowUsageWarning = true;
    permissions = {
      defaultMode = "auto";
      allow = config.lib.permissions.forClaude;
    };
  };

  settingsFile = (pkgs.formats.json { }).generate "claude-code-settings.json" userSettings;
in
{
  imports = [
    ./jj-commit-command.nix
    ./finish-worktree-command.nix
    ./init-devshell-command.nix
    ./init-agents-md-command.nix
    ./mcp.nix
    ./permissions.nix
  ];

  options.my.claude-code.enable = lib.mkEnableOption "Claude Code";

  config = lib.mkIf config.my.claude-code.enable {
    programs.claude-code = {
      enable = true;
      package = pinToCCD1 (fakeCores claude-code-wrapped);
    };

    # Make `claude-statusline` resolvable on PATH so settings.json can
    # reference it by bare name (drift-stable across rebuilds).
    home.packages = [ statusline-script ];

    anti-drift.files = {
      ".claude/settings.json" = {
        source = settingsFile;
        json = true;
      };
      ".claude/mcp.json" = {
        source = mcpFile;
        json = true;
      };
    };

    xdg.desktopEntries.ssh-askpass = {
      name = "ssh-askpass";
      type = "Application";
      exec = "${pkgs.seahorse}/libexec/seahorse/ssh-askpass";
      terminal = false;
    };
  };
}
