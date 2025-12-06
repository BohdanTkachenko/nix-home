{ pkgs-unstable, ... }:
{
  programs.vscode.profiles.default.extensions = with pkgs-unstable.vscode-extensions; [
    hashicorp.hcl
    hashicorp.terraform
    ms-vscode.makefile-tools
  ];

  imports = [
    ./common.nix
  ];
}
