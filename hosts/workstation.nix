{
  config,
  pkgs,
  ...
}:
{
  home.stateVersion = "25.05";
  home.username = "dan";
  home.homeDirectory = "/var/home/dan";

  programs.home-manager.enable = true;
  targets.genericLinux.enable = true;

  programs.chromium-pwa-wmclass-sync.service.enable = true;

  sops.age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";

  dconf.settings = {
    "org/gnome/shell" = {
      favorite-apps = [
        "Gemini.desktop"
        "com.google.Chrome.desktop"
        "org.gnome.Ptyxis.desktop"
        "code.desktop"
        "com.spotify.Client.desktop"
        "beepertexts.desktop"
        "1password.desktop"
        "org.gnome.Nautilus.desktop"
      ];
    };
  };

  imports = [
    ../modules/1password
    ../modules/fonts
    ../modules/bash.nix
    ../modules/easyeffects
    ../modules/fish.nix
    ../modules/flatpak.nix
    ../modules/git
    ../modules/git/personal.nix
    ../modules/gnome.nix
    ../modules/micro.nix
    ../modules/obsidian
    ../modules/ssh
    ../modules/ssh/personal.nix
    ../modules/tealdeer.nix
    ../modules/tools.nix
    ../modules/gemini-cli/gemini-cli.nix
    ../modules/vscode/vscode.nix
  ];
}
