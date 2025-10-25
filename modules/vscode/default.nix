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
      profiles.default = {
        extensions = with pkgs.vscode-extensions; [
          jnoortheen.nix-ide
          ms-python.python
        ];
      };
    };
  };

  home.file.".config/Code/User/settings.json".source = lib.mkForce (
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/home-manager/modules/vscode/settings.json"
  );
}
