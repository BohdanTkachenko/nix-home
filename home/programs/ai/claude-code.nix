{
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:

{
  imports = [
    ./jj-commit-command.nix
  ];

  programs.claude-code = {
    enable = true;
    package = pkgs-unstable.claude-code;
  };
}
