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
  };

  xdg.desktopEntries.ssh-askpass = {
    name = "ssh-askpass";
    type = "Application";
    exec = "${pkgs.seahorse}/libexec/seahorse/ssh-askpass";
    terminal = false;
  };
}
