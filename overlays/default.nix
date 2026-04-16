{ nix-vscode-extensions, ... }:
{
  nixpkgs.overlays = [
    nix-vscode-extensions.overlays.default
  ];

  imports = [
    ../home/modules/options.nix
    ./bambu-studio.nix
    ./google-chrome.nix
    ./riff-overlay.nix
  ];
}
