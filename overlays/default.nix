{ nix-vscode-extensions, ... }:
{
  nixpkgs.overlays = [
    nix-vscode-extensions.overlays.default
  ];

  imports = [
    ./gemini-cli.nix
    ./google-chrome.nix
    ./jujutsu.nix
  ];
}
