{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    nix
    nil
    nixfmt-rfc-style
  ];

  programs = {
    vscode = {
      enable = true;
      package = (config.lib.nixGL.wrap pkgs.vscode);
    };
  };

  programs.vscode.profiles.default.extensions = with pkgs.vscode-extensions; [
    coolbear.systemd-unit-file
    foxundermoon.shell-format
    hashicorp.terraform
    jnoortheen.nix-ide
    ms-python.black-formatter
    ms-python.python
    ms-vscode.makefile-tools
  ];

  home.file.".config/Code/User/settings.json".source = lib.mkForce (
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/home-manager/modules/vscode/settings.json"
  );
}
