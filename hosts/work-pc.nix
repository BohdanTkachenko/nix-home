{ ... }:
{
  imports = [
    ../overlays
    ../home/common.nix
    ../home/hardware/gpu-amd.nix
    ../home/hardware/pc-work.nix
    ../home/work.nix
  ];

  home.homeDirectory = "/usr/local/google/home/bohdant";

  my.google.enable = true;
  my.identity.email = "bohdant@google.com";
  my.ai.gemini.extraFlags = [ "--gfg" ];
  my.vscode.useFHS = false;

  nixpkgs.config.allowUnfree = true;
  services.xremap.enable = false;
}
