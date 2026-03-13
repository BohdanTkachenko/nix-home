{ ... }:
{
  imports = [
    ../overlays
    ../home/common.nix
    ../home/hardware/gpu-amd.nix
    ../home/hardware/lenovo-thinkpad-x1-carbon-gen12.nix
    ../home/work.nix
  ];

  home.homeDirectory = "/home/bohdant";

  my.google.enable = true;
  my.identity.email = "bohdant@google.com";
  my.ai.gemini.extraFlags = [ "--proxy=false" ];
  my.terminal.ptyxis.workstationProfile.enable = true;

  nixpkgs.config.allowUnfree = true;
  services.xremap.enable = false;
}
