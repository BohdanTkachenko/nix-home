{
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

  programs.claude-code = {
    enable = true;
    package = claude-code-wrapped;
    settings = {
      permissions = {
        allow = [
          "Search"
          "WebSearch"
          "WebFetch"
          "Read(/nix/store/**)"
          "Grep"
          "Glob"
          "Bash(wc:*)"
          "Bash(tree:*)"
          "Bash(diff:*)"
          "Bash(rg:*)"
          "Bash(grep:*)"
          "Bash(find:*)"
          "Bash(fd:*)"
          "Bash(cat:*)"
          "Bash(head:*)"
          "Bash(tail:*)"
          "Bash(ls:*)"
        ];
      };
    };
  };

  xdg.desktopEntries.ssh-askpass = {
    name = "ssh-askpass";
    type = "Application";
    exec = "${pkgs.seahorse}/libexec/seahorse/ssh-askpass";
    terminal = false;
  };
}
