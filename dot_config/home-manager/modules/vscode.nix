{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    nix
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
        userSettings = {
          "editor.formatOnSave" = true;
          "editor.tabSize" = 2;
        };
      };
    };
  };
}
