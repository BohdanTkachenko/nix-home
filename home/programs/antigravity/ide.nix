{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  pkgs-antigravity-ide,
  ...
}:
let
  pinToCCD1 = import ../../../lib/pin-to-ccd1.nix { inherit pkgs; };
  settings = import ../vscode-settings.nix { inherit pkgs pkgs-unstable; };

  extensions = import ../vscode-extensions.nix {
    inherit pkgs lib config;
    isAntigravity = true;
  };

  antigravityIdePkg = pkgs-antigravity-ide.antigravity-ide.fhsWithPackages (
    ps: with ps; [
      nodejs
      python3
    ]
  );
in
{
  home.packages = [
    (pinToCCD1 (
      pkgs.vscode-with-extensions.override {
        vscode = antigravityIdePkg;
        vscodeExtensions = extensions;
      }
    ))
  ];

  anti-drift.files = {
    ".config/Antigravity IDE/User/settings.json" = {
      source = (pkgs.formats.json { }).generate "antigravity-settings.json" (
        settings
        // {
          "securecoder.enabled" = true;
        }
      );
      json = true;
    };
  };
}
