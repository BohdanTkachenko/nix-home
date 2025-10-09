{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    gemini-cli
  ];

  home.file.".gemini/settings.json".source = lib.mkForce (
    config.lib.file.mkOutOfStoreSymlink "${chezmoiData.sourceDir}/dot_config/home-manager/modules/gemini-cli/settings.json"
  );
}
