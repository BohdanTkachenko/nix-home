{
  config,
  isWork,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:
{
  home.packages = with pkgs-unstable; [
    # Nix
    nix
    nil
    nixfmt-rfc-style
    # Terraform
    terraform-ls
    # Terraform wrapper that executes tofu
    (pkgs.writeShellScriptBin "terraform" ''
      exec ${pkgs-unstable.opentofu}/bin/tofu "$@"
    '')
  ];

  programs = {
    vscode = {
      enable = true;
      package = (config.lib.nixGL.wrap pkgs-unstable.vscode);
    };
  };

  programs.vscode.profiles.default.extensions =
    with pkgs-unstable.vscode-extensions;
    [
      coolbear.systemd-unit-file
      davidanson.vscode-markdownlint
      foxundermoon.shell-format
      jnoortheen.nix-ide
      ms-python.black-formatter
      ms-python.python
      ms-vscode.makefile-tools
      rust-lang.rust-analyzer
      tamasfe.even-better-toml
      yzhang.markdown-all-in-one
    ]
    ++ lib.optionals (!isWork) [
      # https://github.com/NixOS/nixpkgs/issues/464202
      # anthropic.claude-code
      hashicorp.hcl
      hashicorp.terraform
    ];

  home.file.".config/Code/User/settings.json".source = lib.mkForce (
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nix/home/programs/vscode/settings.json"
  );
}
