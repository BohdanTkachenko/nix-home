{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ansible
    direnv
    gh
    glab
    go
    google-cloud-sdk
    kubectl
    libvirt
    nodejs_24
    opentofu
    sops
    terragrunt
  ];

  imports = [
    ./cli.nix
    ../modules/gemini-cli
    ../modules/ssh/personal.nix
  ];
}
