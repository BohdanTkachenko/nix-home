{ nix-vscode-extensions, ... }:
{
  nixpkgs.overlays = [
    nix-vscode-extensions.overlays.default
  ];

  imports = [
    ../home/modules/options.nix
    ./bambu-studio.nix
    ./gemini-cli.nix
    ./google-chrome.nix
    ./jujutsu.nix
    ./riff-overlay.nix
    ./web-apps.nix
  ];
}
