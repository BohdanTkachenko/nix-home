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
  settingsFile = (pkgs.formats.json { }).generate "vscode-settings.json" settings;
in
{
  home.packages =
    with pkgs-unstable;
    [
      nix
      nil
      nixd
      nixfmt
    ]
    ++ lib.optionals (!config.my.google.enable) [
      terraform-ls
      (pkgs.writeShellScriptBin "terraform" ''
        exec ${pkgs-unstable.opentofu}/bin/tofu "$@"
      '')
    ];

  programs.vscode.enable = true;
  programs.vscode.package =
    # On the work PC, the home directory is under /usr, which conflicts with
    # the bubblewrap sandbox used by the vscode-fhs package. The sandbox
    # hides the host's /usr, making the home directory inaccessible.
    # As a workaround, we use the non-FHS version of VS Code on this specific machine.
    pinToCCD1 (
      if !config.my.vscode.useFHS then pkgs-unstable.vscode else (config.lib.nixGL.wrap pkgs-unstable.vscode.fhs)
    );
  programs.vscode.mutableExtensionsDir = false;
  programs.vscode.profiles.default.extensions = import ./vscode-extensions.nix { inherit pkgs lib config; };

  anti-drift.files.".config/Code/User/settings.json" = { source = settingsFile; json = true; };
}
