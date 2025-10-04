{ pkgs, ... }:

{

  home.packages = with pkgs; [
    ansible
    bat
    direnv
    eza
    fd
    gemini-cli
    gh
    glab
    go
    kubectl
    micro
    nodejs_24
    nix
    nixfmt-rfc-style
    opentofu
    ripgrep
    tealdeer
    terragrunt
    trash-cli
    sops
    ugrep
    yq
  ];
}
