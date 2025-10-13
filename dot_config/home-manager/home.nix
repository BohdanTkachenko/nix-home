{
  chezmoiData,
  features,
  config,
  lib,
  pkgs,
  ...
}:
{
  home.stateVersion = "25.05";
  home.username = chezmoiData.username;
  home.homeDirectory = chezmoiData.homeDirectory;

  programs.home-manager.enable = true;
  targets.genericLinux.enable = true;

  programs.chromium-pwa-wmclass-sync.service.enable = true;

  home.sessionVariables.EDITOR = "micro";
  home.sessionVariables.VISUAL = "micro";

  sops.age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";

  home.packages = with pkgs; [
    _1password-gui
    chezmoi
    beeper
    nerd-fonts.hack
    nerd-fonts.droid-sans-mono
    nerd-fonts.roboto-mono
  ];

  imports = [
    ./modules/bash.nix
    ./modules/fish.nix
    ./modules/flatpak.nix
    ./modules/git.nix
    ./modules/gnome.nix
    ./modules/micro.nix
    ./modules/ssh
    ./modules/systemd.nix
    ./modules/tealdeer.nix
    ./modules/tools.nix
    ./modules/gemini-cli/gemini-cli.nix
    ./modules/vscode/vscode.nix
  ]
  ++ (lib.optional features.xremap ./modules/xremap.nix);
}
