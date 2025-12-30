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
      jjk.jjk
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

  programs.vscode.profiles.default.userSettings = {
    # Fonts
    editor.fontFamily = "'MesloLGL Nerd Font Mono', 'Droid Sans Mono', 'monospace', monospace";
    editor.fontSize = 16;
    terminal.integrated.fontFamily = "MesloLGL Nerd Font";

    # Disable updates
    extensions.autoCheckUpdates = false;
    extensions.autoUpdate = false;
    update.mode = "none";

    # Formatting
    editor.formatOnSave = true;
    "[dockerfile]".editor.defaultFormatter = "ms-azuretools.vscode-containers";
    "[markdown]".editor.defaultFormatter = "esbenp.prettier-vscode";
    "[terraform-vars]".editor.defaultFormatter = "hashicorp.terraform";
    "[terraform]".editor.defaultFormatter = "hashicorp.terraform";

    # General
    editor.rulers = [ 80 ];
    editor.tabSize = 2;
    editor.wordWrap = "on";
    explorer.confirmDragAndDrop = false;
    files.autoSave = "onFocusChange";
    workbench.startupEditor = "none";
    puppet.editorService.enable = false;
  };
}
