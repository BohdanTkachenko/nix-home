{
  pkgs-unstable,
  pkgs-master,
  nix-vscode-extensions,
  pkgs-claude-code ? null,
  ...
}:
{
  _module.args = {
    inherit pkgs-unstable pkgs-master nix-vscode-extensions;
  } // (if pkgs-claude-code != null then { inherit pkgs-claude-code; } else {});

  imports = [
    ../../overlays
    ../modules/options.nix
    ../common.nix
  ];
}
