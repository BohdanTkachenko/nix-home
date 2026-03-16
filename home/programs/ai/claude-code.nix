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
in
{
  imports = [
    ./jj-commit-command.nix
  ];

  config = lib.mkIf (config.my.environment == "personal") {
    programs.claude-code = {
      enable = true;
      package = claude-code-wrapped;
    };

    anti-drift.files.".claude/settings.json" = {
      source = (pkgs.formats.json { }).generate "claude-code-settings.json" {
        "$schema" = "https://json.schemastore.org/claude-code-settings.json";
        effortLevel = "high";
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
      json = true;
    };

    xdg.desktopEntries.ssh-askpass = {
      name = "ssh-askpass";
      type = "Application";
      exec = "${pkgs.seahorse}/libexec/seahorse/ssh-askpass";
      terminal = false;
    };
  };
}
