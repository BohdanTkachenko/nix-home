{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ../programs/1password.nix
    ../programs/fonts.nix
    ../programs/gnome.nix
    ../programs/ptyxis.nix
    ../programs/vscode.nix
    ../programs/web-apps.nix
  ];

  options.my.gui = {
    apps = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = with pkgs; [
        cameractrls-gtk4
        mission-center
        obsidian
        riff
        spotify
      ];
      description = "List of GUI apps to install, which might need wrapping on non-NixOS systems";
    };

    wrapper = lib.mkOption {
      type = lib.types.functionTo lib.types.package;
      default = lib.id;
      description = "Wrapper function to apply to GUI apps (e.g. nixGL)";
    };
  };

  config = {
    programs.chromium-pwa-wmclass-sync.service.enable = true;

    home.packages = map config.my.gui.wrapper config.my.gui.apps;

    xdg.autostart.entries = [
      "${pkgs.google-chrome}/share/applications/google-chrome.desktop"
    ];
  };
}
