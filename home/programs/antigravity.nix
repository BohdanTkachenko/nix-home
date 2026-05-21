{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:
let
  pinToCCD1 = import ../../lib/pin-to-ccd1.nix { inherit pkgs; };
  settings = import ./vscode-settings.nix { inherit pkgs pkgs-unstable; };
  settingsFile = (pkgs.formats.json { }).generate "antigravity-settings.json" settings;

  extensions = import ./vscode-extensions.nix { inherit pkgs lib config; isAntigravity = true; };

  antigravityPkg = pkgs-unstable.antigravity-fhs;

  antigravityWithExtensions = pkgs.vscode-with-extensions.override {
    vscode = antigravityPkg;
    vscodeExtensions = extensions;
  };
in
{
  config = lib.mkIf (config.my.environment == "personal") {
    home.packages = [
      (pinToCCD1 antigravityWithExtensions)
    ];

    home.file.".local/share/pixmaps/antigravity.png".source = "${antigravityPkg}/share/pixmaps/antigravity.png";
    home.file.".local/share/icons/antigravity.png".source = "${antigravityPkg}/share/pixmaps/antigravity.png";

    anti-drift.files.".config/Antigravity/User/settings.json" = {
      source = settingsFile;
      json = true;
    };
  };
}
