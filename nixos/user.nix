# User configuration and Home Manager setup
{ pkgs, ... }:

{
  users.users.dan = {
    isNormalUser = true;
    description = "Dan";
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
      "input"
      "tss"
    ];
    shell = pkgs.fish;
  };

  programs.fish.enable = true;

  home-manager.useUserPackages = true;
  home-manager.users.dan =
    { config, lib, ... }:
    {
      imports = [
        ../profiles/common.nix
        ../profiles/personal.nix
      ];

      home = {
        username = lib.mkForce "dan";
        homeDirectory = lib.mkForce "/home/dan";
        stateVersion = lib.mkForce "25.11";
      };

      sops.age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";

      targets.genericLinux.enable = lib.mkForce false;
    };
}
