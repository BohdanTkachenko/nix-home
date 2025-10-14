{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  bootstrap,
  ...
}:

{
  sops.secrets.geminiApiKey.sopsFile = ./secrets.yaml;

  home.packages = [
    (pkgs.writeShellScriptBin "gemini" ''
      #!${pkgs.runtimeShell}
      export GEMINI_API_KEY=$(cat "${config.sops.secrets.geminiApiKey.path}")
      exec "${lib.getExe pkgs-unstable.gemini-cli}" "$@"
    '')
  ];

  home.file.".gemini/settings.json".source = lib.mkForce (
    config.lib.file.mkOutOfStoreSymlink "${bootstrap.sourceDir}/modules/gemini-cli/settings.json"
  );
}
