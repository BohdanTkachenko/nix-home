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
    ../gui/default.nix
    ../cli/default.nix
    ../services/screenshot-path-clipboard.nix
    ../services/yubikey-touch-notifier.nix
  ];

  config = {
    # 1. Ptyxis terminal, Ask Claude wrapper, and Terraform/Tofu packages
    home.packages = [
      pkgs.ptyxis
      (pkgs.writeShellScriptBin "ask" ''
        exec ask-claude "$@"
      '')
      pkgs-unstable.terraform-ls
      (pkgs.writeShellScriptBin "terraform" ''
        exec ${pkgs-unstable.opentofu}/bin/tofu "$@"
      '')
    ];

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
  };
}
