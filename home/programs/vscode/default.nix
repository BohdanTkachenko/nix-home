{
  config,
  isWork,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:
{
  home.packages =
    with pkgs-unstable;
    [
      nix
      nil
      nixfmt-rfc-style
    ]
    ++ lib.optionals (!isWork) [
      puppet
      terraform-ls
      (pkgs.writeShellScriptBin "terraform" ''
        exec ${pkgs-unstable.opentofu}/bin/tofu "$@"
      '')
    ];

  programs.vscode.enable = true;
  programs.vscode.package = (config.lib.nixGL.wrap pkgs-unstable.vscode.fhs);
  programs.vscode.mutableExtensionsDir = false;
  programs.vscode.profiles.default.extensions =
    with pkgs.nix-vscode-extensions.vscode-marketplace;
    [
      coolbear.systemd-unit-file
      davidanson.vscode-markdownlint
      foxundermoon.shell-format
      jnoortheen.nix-ide
      mkhl.direnv
      ms-python.black-formatter
      ms-python.python
      ms-vscode.makefile-tools
      puppet.puppet-vscode
      yzhang.markdown-all-in-one
    ]
    ++ lib.optionals (!isWork) [
      anthropic.claude-code
      hashicorp.hcl
      hashicorp.terraform
      rust-lang.rust-analyzer
      tamasfe.even-better-toml
    ];

  home.file.".config/Code/User/settings.json".source = lib.mkForce (
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nix/home/programs/vscode/settings.json"
  );
}
