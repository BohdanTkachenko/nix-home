{
  pkgs-unstable,
  pkgs-master,
  nix-vscode-extensions,
  ...
}:
{
  _module.args = {
    inherit pkgs-unstable pkgs-master nix-vscode-extensions;
  };

  imports = [
    ../../overlays
    ../modules/options.nix
    ../common.nix
  ];
}
