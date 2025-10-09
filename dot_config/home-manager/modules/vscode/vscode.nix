{
  chezmoiData,
  config,
  lib,
  pkgs,
  ...
}:
{
  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    nix
    nixd
    nixfmt-rfc-style
  ];

  programs = {
    vscode = {
      enable = true;
      package = pkgs.vscode;
      profiles.default = {
        extensions = with pkgs.vscode-extensions; [
          jnoortheen.nix-ide
          ms-python.python
        ];
      };
    };
  };

  home.file.".config/Code/User/settings.json".source = lib.mkForce (
    config.lib.file.mkOutOfStoreSymlink "${chezmoiData.sourceDir}/dot_config/home-manager/modules/vscode/settings.json"
  );
}
