{ nix-vscode-extensions, ... }:
{
  nixpkgs.overlays = [
    nix-vscode-extensions.overlays.default
  ];

  imports = [
    ./bambu-studio.nix
    ./gemini-cli.nix
    ./google-chrome.nix
    ./jujutsu.nix
    ./riff-overlay.nix
    ./web-apps.nix
  ];
}
