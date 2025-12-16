{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  isWorkLaptop ? false,
  isWorkPC ? false,
  ...
}:
let
  geminiPkg =
    if isWorkPC then
      (pkgs.writeScriptBin "gemini" ''
        #!/bin/sh
        /google/bin/releases/gemini-cli/tools/gemini --gfg "$@"
      '')
    else if isWorkLaptop then
      (pkgs.writeScriptBin "gemini" ''
        #!/bin/sh
        "${pkgs-unstable.gemini-cli}/bin/gemini --proxy=false "$@"
      '')
    else
      pkgs-unstable.gemini-cli;
in
{
  programs.gemini-cli = {
    enable = true;
    package = geminiPkg;
  };

  home.file.".gemini/settings.json" = lib.mkIf (!isWorkPC) {
    source = lib.mkForce (
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nix/home/programs/gemini-cli/settings.json"
    );
  };
}
