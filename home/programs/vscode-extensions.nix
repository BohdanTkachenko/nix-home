{ pkgs, lib, config, isAntigravity ? false }:
with pkgs.nix-vscode-extensions.vscode-marketplace;
[
  coolbear.systemd-unit-file
  davidanson.vscode-markdownlint
  foxundermoon.shell-format
  github.vscode-github-actions
  jnoortheen.nix-ide
  mkhl.direnv
  ms-dotnettools.csharp
  ms-python.black-formatter
  ms-python.python
  ms-vscode.cpptools-extension-pack
  ms-vscode.makefile-tools
  puppet.puppet-vscode
  thenuprojectcontributors.vscode-nushell-lang
  jj-view.jj-view
  yzhang.markdown-all-in-one
]
++ lib.optionals (!isAntigravity) [
  google.gemini-cli-vscode-ide-companion
  google.geminicodeassist
]
++ lib.optionals (!config.my.google.enable) [
  anthropic.claude-code
  rust-lang.rust-analyzer
  tamasfe.even-better-toml
]
