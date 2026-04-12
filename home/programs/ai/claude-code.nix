{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:

let
  # MCP servers are declared with `${VAR}` placeholders for secrets. Claude
  # Code natively expands these from the process env at load time (see the
  # `Sy6` function in cli.js), the same way VS Code's mcp.json supports
  # `${env:FOO}` and Gemini CLI supports `$VAR`/`${VAR}`. The config file
  # itself contains no secrets and is rendered to ~/.claude/mcp.json via
  # anti-drift; the wrapper below exports the env vars from sops-rendered
  # secret files just before exec, then passes --mcp-config to claude.
  mcpFile = (pkgs.formats.json { }).generate "claude-mcp.json" {
    mcpServers = {
      home-assistant = {
        type = "http";
        url = "\${CLAUDE_HA_MCP_URL}";
        oauth = {
          clientId = "http://localhost:48721";
          callbackPort = 48721;
        };
      };
      github = {
        command = "${github-mcp-server}/bin/github-mcp-server";
        args = [ "stdio" ];
        env = {
          GITHUB_PERSONAL_ACCESS_TOKEN = "\${GITHUB_PERSONAL_ACCESS_TOKEN}";
        };
      };
      plane = {
        type = "http";
        url = "https://mcp.plane.so/http/api-key/mcp";
        headers = {
          Authorization = "Bearer \${PLANE_API_KEY}";
          X-Workspace-slug = "ideasmash";
        };
      };
    };
  };

  # Helper: produce a `--run` snippet that exports VAR from a sops-rendered
  # secret file. Uses `2>/dev/null || true` so a missing secret doesn't abort
  # the wrapper script (makeWrapper sets `bash -e`).
  exportSecret =
    file: var:
    ''export ${var}="$(cat "$HOME/.config/sops-nix/secrets/${file}" 2>/dev/null || true)"'';

  claude-code-wrapped = pkgs.symlinkJoin {
    name = "claude-code-wrapped";
    paths = [ pkgs-unstable.claude-code ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    # The --mcp-config path is single-quoted so nothing expands at build time;
    # bash expands $HOME at exec time when the wrapper script runs.
    postBuild = ''
      wrapProgram $out/bin/claude \
        --set SUDO_ASKPASS "${pkgs.seahorse}/libexec/seahorse/ssh-askpass" \
        --set UV_PYTHON_PREFERENCE only-system \
        --prefix PATH : "${pkgs.python3}/bin" \
        --add-flags '--mcp-config "''$HOME/.claude/mcp.json"' \
        --run '${exportSecret "github-pat" "GITHUB_PERSONAL_ACCESS_TOKEN"}' \
        --run '${exportSecret "plane-api-key" "PLANE_API_KEY"}' \
        --run '${exportSecret "claude-ha-mcp-url" "CLAUDE_HA_MCP_URL"}'
    '';
  };

  github-mcp-server = pkgs.buildGoModule {
    pname = "github-mcp-server";
    version = "0.2.0-unstable";
    src = pkgs.fetchFromGitHub {
      owner = "github";
      repo = "github-mcp-server";
      rev = "b01f7f5b6aa4c251136f9adbc51d489f241a07a4";
      hash = "sha256-hcIE6aAF/B3UAsZ1ESN7Rqi4F7eVEUaLSIEZRdwVduE=";
    };
    vendorHash = "sha256-q21hnMnWOzfg7BGDl4KM1I3v0wwS5sSxzLA++L6jO4s=";
    subPackages = [ "cmd/github-mcp-server" ];
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

    effortLevel = "high";
    enabledPlugins = {
      "gopls-lsp@claude-plugins-official" = true;
      "rust-analyzer-lsp@claude-plugins-official" = true;
    };
    statusLine = {
      type = "command";
      command = "claude-statusline";
    };
    voiceEnabled = true;
    permissions = {
      allow = [
        "Search"
        "WebSearch"
        "WebFetch"
        "Read(//nix//store//**)"
        "Grep(//nix//store//**)"
        "Glob(//nix//store//**)"
        "Grep"
        "Glob"
        # General CLI
        "Bash(awk:*)"
        "Bash(basename:*)"
        "Bash(cat:*)"
        "Bash(curl:*)"
        "Bash(cut:*)"
        "Bash(date:*)"
        "Bash(diff:*)"
        "Bash(dig:*)"
        "Bash(dirname:*)"
        "Bash(du:*)"
        "Bash(env:*)"
        "Bash(fd:*)"
        "Bash(file:*)"
        "Bash(find:*)"
        "Bash(grep:*)"
        "Bash(head:*)"
        "Bash(host:*)"
        "Bash(jq:*)"
        "Bash(ls:*)"
        "Bash(man:*)"
        "Bash(md5sum:*)"
        "Bash(nslookup:*)"
        "Bash(printenv:*)"
        "Bash(readlink:*)"
        "Bash(rg:*)"
        "Bash(sed:*)"
        "Bash(sha256sum:*)"
        "Bash(sort:*)"
        "Bash(stat:*)"
        "Bash(tail:*)"
        "Bash(tokei:*)"
        "Bash(tr:*)"
        "Bash(tree:*)"
        "Bash(uname:*)"
        "Bash(uniq:*)"
        "Bash(wc:*)"
        "Bash(wget:*)"
        "Bash(which:*)"
        "Bash(yq:*)"

        # Cargo (read-only / build)
        "Bash(cargo bench:*)"
        "Bash(cargo build:*)"
        "Bash(cargo check:*)"
        "Bash(cargo clippy:*)"
        "Bash(cargo doc:*)"
        "Bash(cargo metadata:*)"
        "Bash(cargo read-manifest:*)"
        "Bash(cargo search:*)"
        "Bash(cargo test:*)"
        "Bash(cargo tree:*)"
        "Bash(cargo verify-project:*)"

        # Go (read-only / build)
        "Bash(go build:*)"
        "Bash(go doc:*)"
        "Bash(go env:*)"
        "Bash(go list:*)"
        "Bash(go mod graph:*)"
        "Bash(go mod verify:*)"
        "Bash(go test:*)"
        "Bash(go version:*)"
        "Bash(go vet:*)"

        # GitHub CLI (read-only)
        "Bash(gh api:*)"
        "Bash(gh issue list:*)"
        "Bash(gh issue status:*)"
        "Bash(gh issue view:*)"
        "Bash(gh pr checks:*)"
        "Bash(gh pr diff:*)"
        "Bash(gh pr list:*)"
        "Bash(gh pr status:*)"
        "Bash(gh pr view:*)"
        "Bash(gh repo list:*)"
        "Bash(gh repo view:*)"
        "Bash(gh run list:*)"
        "Bash(gh run view:*)"
        "Bash(gh search:*)"
        "Bash(gh status:*)"

        # Git (read-only)
        "Bash(git blame:*)"
        "Bash(git diff:*)"
        "Bash(git log:*)"
        "Bash(git show:*)"
        "Bash(git status:*)"

        # npm (read-only / build)
        "Bash(npm audit:*)"
        "Bash(npm explain:*)"
        "Bash(npm list:*)"
        "Bash(npm outdated:*)"
        "Bash(npm run:*)"
        "Bash(npm search:*)"
        "Bash(npm test:*)"
        "Bash(npm view:*)"
        "Bash(npx:*)"

        # Jujutsu (read-only)
        "Bash(jj diff:*)"
        "Bash(jj log:*)"
        "Bash(jj show:*)"
        "Bash(jj status:*)"
        "Bash(jj workspace list:*)"
        "Bash(jj workspace root:*)"

        # systemctl (read-only)
        "Bash(systemctl cat:*)"
        "Bash(systemctl is-active:*)"
        "Bash(systemctl is-enabled:*)"
        "Bash(systemctl list-dependencies:*)"
        "Bash(systemctl list-timers:*)"
        "Bash(systemctl list-unit-files:*)"
        "Bash(systemctl list-units:*)"
        "Bash(systemctl show:*)"
        "Bash(systemctl status:*)"
        "Bash(journalctl:*)"

        # Plane (read-only)
        "mcp__plane__get_me"
        "mcp__plane__get_project_features"
        "mcp__plane__get_project_members"
        "mcp__plane__get_project_worklog_summary"
        "mcp__plane__get_workspace_features"
        "mcp__plane__get_workspace_members"
        "mcp__plane__list_archived_cycles"
        "mcp__plane__list_archived_modules"
        "mcp__plane__list_cycle_work_items"
        "mcp__plane__list_cycles"
        "mcp__plane__list_epics"
        "mcp__plane__list_initiatives"
        "mcp__plane__list_intake_work_items"
        "mcp__plane__list_labels"
        "mcp__plane__list_milestone_work_items"
        "mcp__plane__list_milestones"
        "mcp__plane__list_module_work_items"
        "mcp__plane__list_modules"
        "mcp__plane__list_projects"
        "mcp__plane__list_states"
        "mcp__plane__list_work_item_activities"
        "mcp__plane__list_work_item_comments"
        "mcp__plane__list_work_item_links"
        "mcp__plane__list_work_item_properties"
        "mcp__plane__list_work_item_relations"
        "mcp__plane__list_work_item_types"
        "mcp__plane__list_work_items"
        "mcp__plane__list_work_logs"
        "mcp__plane__retrieve_cycle"
        "mcp__plane__retrieve_epic"
        "mcp__plane__retrieve_initiative"
        "mcp__plane__retrieve_intake_work_item"
        "mcp__plane__retrieve_label"
        "mcp__plane__retrieve_milestone"
        "mcp__plane__retrieve_module"
        "mcp__plane__retrieve_project"
        "mcp__plane__retrieve_project_page"
        "mcp__plane__retrieve_state"
        "mcp__plane__retrieve_work_item"
        "mcp__plane__retrieve_work_item_activity"
        "mcp__plane__retrieve_work_item_by_identifier"
        "mcp__plane__retrieve_work_item_comment"
        "mcp__plane__retrieve_work_item_link"
        "mcp__plane__retrieve_work_item_property"
        "mcp__plane__retrieve_work_item_type"
        "mcp__plane__retrieve_workspace_page"
        "mcp__plane__search_work_items"

        # Nix (read-only)
        "Bash(nix build:*)"
        "Bash(nix derivation show:*)"
        "Bash(nix eval:*)"
        "Bash(nix flake:*)"
        "Bash(nix hash:*)"
        "Bash(nix path-info:*)"
        "Bash(nix search:*)"
        "Bash(nix store:*)"
        "Bash(nix why-depends:*)"
        "Bash(nix-instantiate --eval:*)"
        "Bash(nix-store --query:*)"
        "Bash(nix-store -q:*)"
        "Bash(nix-prefetch-url:*)"
        "Bash(nix-hash:*)"
        "Bash(nixos-option:*)"
      ];
    };
  };

  settingsFile = (pkgs.formats.json { }).generate "claude-code-settings.json" userSettings;
in
{
  imports = [
    ./jj-commit-command.nix
  ];

  options.my.claude-code.enable = lib.mkEnableOption "Claude Code";

  config = lib.mkIf config.my.claude-code.enable {
    programs.claude-code = {
      enable = true;
      package = claude-code-wrapped;
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

    sops.secrets.claude-ha-mcp-url = lib.mkIf config.my.secrets.sops.enable {
      sopsFile = ./secrets/claude-code.yaml;
      key = "ha_mcp_url";
    };

    sops.secrets.github-pat = lib.mkIf config.my.secrets.sops.enable {
      sopsFile = ./secrets/claude-code.yaml;
      key = "github_pat";
    };

    sops.secrets.plane-api-key = lib.mkIf config.my.secrets.sops.enable {
      sopsFile = ./secrets/claude-code.yaml;
      key = "plane_api_key";
    };

    xdg.desktopEntries.ssh-askpass = {
      name = "ssh-askpass";
      type = "Application";
      exec = "${pkgs.seahorse}/libexec/seahorse/ssh-askpass";
      terminal = false;
    };
  };
}
