{ pkgs, ... }:
{
  home.packages = with pkgs; [
    act
    ansible
    cilium-cli
    direnv
    gh
    glab
    go
    google-cloud-sdk
    jujutsu
    kubectl
    libvirt
    nodejs_24
    opentofu
    sops
    strace
    terragrunt
  ];

  imports = [
    ./cli.nix
    ../modules/gemini-cli
    ../modules/ssh/personal.nix
  ];
}
