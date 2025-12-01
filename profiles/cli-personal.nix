{ pkgs-unstable, ... }:
{
  home.packages = with pkgs-unstable; [
    act
    ansible
    cilium-cli
    claude-code
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
    ../modules/jujutsu
    ../modules/ssh/personal.nix
  ];
}
