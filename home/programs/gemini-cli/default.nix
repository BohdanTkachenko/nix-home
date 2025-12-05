{
  config,
  lib,
  pkgs-unstable,
  ...
}:

{
  home.packages = [
    pkgs-unstable.gemini-cli
  ];

  home.file.".gemini/settings.json".source = lib.mkForce (
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nix/modules/gemini-cli/settings.json"
  );
}
