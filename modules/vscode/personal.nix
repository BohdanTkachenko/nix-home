{ pkgs, ... }:
{
  programs.vscode.profiles.default.extensions = with pkgs.vscode-extensions; [
    hashicorp.terraform
    ms-vscode.makefile-tools
  ];

  imports = [
    ./default.nix
  ];
}
