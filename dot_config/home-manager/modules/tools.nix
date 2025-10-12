{ pkgs, ... }:

{
  home.packages = with pkgs; [
    ansible
    bat
    direnv
    eza
    fd
    gh
    glab
    go
    kubectl
    nodejs_24
    opentofu
    ripgrep
    terragrunt
    trash-cli
    sops
    ugrep
    yq
  ];
}
