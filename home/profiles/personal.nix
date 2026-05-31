{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:
{
  imports = [
    ./common.nix
    ../cli/default.nix
    ../programs/antigravity
    ../gui/default.nix
    ../services/screenshot-path-clipboard.nix
    ../services/yubikey-touch-notifier.nix
  ];

  config = lib.mkMerge [
    {
      # Ask Claude wrapper and Terraform/Tofu packages (headless-safe).
      home.packages = [
        (pkgs.writeShellScriptBin "ask" ''
          exec ask-claude "$@"
        '')
        pkgs-unstable.terraform-ls
        (pkgs.writeShellScriptBin "terraform" ''
          exec ${pkgs-unstable.opentofu}/bin/tofu "$@"
        '')
      ];
    }

    (lib.mkIf config.my.gui.enable {
      # 1. Ptyxis terminal
      home.packages = [ pkgs.ptyxis ];

      # 2. 1Password silent autostart shortcut
      xdg.autostart.entries = [
        "${
          pkgs.makeDesktopItem {
            name = "1password-silent";
            desktopName = "1Password";
            exec = "${pkgs._1password-gui}/bin/1password -silent";
          }
        }/share/applications/1password-silent.desktop"
      ];

      # 3. Personal-only VS Code extensions
      programs.vscode.profiles.default.extensions = with pkgs.nix-vscode-extensions.vscode-marketplace; [
        anthropic.claude-code
        rust-lang.rust-analyzer
        tamasfe.even-better-toml
      ];
    })
  ];
}
