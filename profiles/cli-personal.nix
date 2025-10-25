{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ansible
    direnv
    gh
    glab
    go
    nodejs_24
    kubectl
    opentofu
    terragrunt
    sops
  ];

  imports = [
    ../modules/gemini-cli
    ../modules/ssh/personal.nix
  ];
}
