{
  config,
  isWork,
  isWorkPC,
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
      nixfmt
    ]
    ++ lib.optionals (!isWork) [
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
    if isWorkPC then pkgs-unstable.vscode else (config.lib.nixGL.wrap pkgs-unstable.vscode.fhs);
  programs.vscode.mutableExtensionsDir = false;
  programs.vscode.profiles.default.extensions =
    with pkgs.nix-vscode-extensions.vscode-marketplace;
    [
      coolbear.systemd-unit-file
      davidanson.vscode-markdownlint
      foxundermoon.shell-format
      github.vscode-github-actions
      google.gemini-cli-vscode-ide-companion
      google.geminicodeassist
      jnoortheen.nix-ide
      mkhl.direnv
      ms-python.black-formatter
      ms-python.python
      ms-vscode.makefile-tools
      puppet.puppet-vscode
      tauri-apps.tauri-vscode
      thenuprojectcontributors.vscode-nushell-lang
      visualjj.visualjj
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
    "[markdown]".editor.defaultFormatter = "yzhang.markdown-all-in-one";
    "[terraform-vars]".editor.defaultFormatter = "hashicorp.terraform";
    "[terraform]".editor.defaultFormatter = "hashicorp.terraform";

    # General
    editor.rulers = [ 80 ];
    editor.tabSize = 2;
    editor.wordWrap = "on";
    explorer.confirmDragAndDrop = false;
    files.autoSave = "onFocusChange";
    workbench.startupEditor = "none";

    # Extensions
    puppet.editorService.enable = false;
    "claudeCode.preferredLocation" = "sidebar";
    geminicodeassist.project = "gen-lang-client-0113783863";
    http.systemCertificatesNode = true; # Needed for Gemini Code Assist
    nushellLanguageServer.nushellExecutablePath = "${pkgs-unstable.nushell}/bin/nu";
    "visualjj.showSourceControlColocated" = true;
    "rust-analyzer.runnables.command" = "${pkgs-unstable.cargo}/bin/cargo";
  };
}
