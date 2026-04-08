{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:

let
  claude-code-wrapped = pkgs.symlinkJoin {
    name = "claude-code-wrapped";
    paths = [ pkgs-unstable.claude-code ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/claude \
        --set SUDO_ASKPASS "${pkgs.seahorse}/libexec/seahorse/ssh-askpass"
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
      let parts = $display | split row "/"
      if ($parts | length) <= 2 { $display } else {
        $parts | last 2 | str join "/"
      }
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
          )
        '
      } | complete
      let trimmed = $out.stdout | str trim
      if $out.exit_code == 0 and $trimmed != "" { $" ($trimmed)" } else { "" }
    }

    def fmt-pct [label: string, val: any] {
      if $val == null { "" } else { $" ($label):($val | math round)%" }
    }

    def main [] {
      let input = $in | from json
      let cwd = $input | get -o cwd | default ""
      let model = $input | get -o model.display_name | default ""
      let model_part = if $model != "" { $"  ($model)" } else { "" }
      let ctx = fmt-pct "ctx" ($input | get -o context_window.remaining_percentage)
      let five = fmt-pct "5h" ($input | get -o rate_limits.five_hour.used_percentage)
      let week = fmt-pct "7d" ($input | get -o rate_limits.seven_day.used_percentage)

      print -n ([(dir $cwd) (jj-info $cwd) $model_part $ctx $five $week] | str join "" | str trim)
    }
  '';

  managedSettings = {
    "$schema" = "https://json.schemastore.org/claude-code-settings.json";

    enableAllProjectMcpServers = true;
    allowManagedHooksOnly = false;
    allowManagedMcpServersOnly = false;
    allowManagedPermissionRulesOnly = false;
    sandbox.filesystem.allowManagedReadPathsOnly = false;
    sandbox.network.allowManagedDomainsOnly = false;

    effortLevel = "high";
    enabledPlugins = {
      "gopls-lsp@claude-plugins-official" = true;
    };
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
        "Bash(nixos-option:*)"
      ];
    };
  };

  managedMcp = {
    mcpServers = {
      home-assistant = {
        type = "http";
        url = config.sops.placeholder.claude-ha-mcp-url;
        oauth = {
          clientId = "http://localhost:48721";
          callbackPort = 48721;
        };
      };
      github = {
        command = "${github-mcp-server}/bin/github-mcp-server";
        args = [ "stdio" ];
        env = {
          GITHUB_PERSONAL_ACCESS_TOKEN = config.sops.placeholder.github-pat;
        };
      };
    };
  };
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

    home.file.".claude/managed-settings.json".text = builtins.toJSON managedSettings;

    home.activation.claudeStatusLine = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${pkgs.nushell}/bin/nu -c '
        let settings = $"($env.HOME)/.claude/settings.json"
        let expected = "${statusline-script}/bin/claude-statusline"
        let data = if ($settings | path exists) {
          open $settings
        } else {
          mkdir ($settings | path dirname)
          {}
        }
        if ($data | get -o statusLine.command) != $expected {
          $data | upsert statusLine {type: command, command: $expected} | save -f $settings
        }
      '
    '';

    sops.secrets.claude-ha-mcp-url = lib.mkIf config.my.secrets.sops.enable {
      sopsFile = ./secrets/claude-code.yaml;
      key = "ha_mcp_url";
    };

    sops.secrets.github-pat = lib.mkIf config.my.secrets.sops.enable {
      sopsFile = ./secrets/claude-code.yaml;
      key = "github_pat";
    };

    sops.templates."claude-managed-mcp" = lib.mkIf config.my.secrets.sops.enable {
      content = builtins.toJSON managedMcp;
      path = "${config.home.homeDirectory}/.claude/managed-mcp.json";
    };

    xdg.desktopEntries.ssh-askpass = {
      name = "ssh-askpass";
      type = "Application";
      exec = "${pkgs.seahorse}/libexec/seahorse/ssh-askpass";
      terminal = false;
    };
  };
}
