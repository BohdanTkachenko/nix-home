# Common machine configuration shared between all personal machines
{ lib, pkgs, ... }:
{
  imports = [
    ../nixos/common.nix
  ];

  users.users.dan = {
    isNormalUser = true;
    description = "Dan";
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
      "input"
    ];
    shell = pkgs.fish;
  };

  programs.fish.enable = true;

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  networking.useDHCP = lib.mkDefault true;

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
        stateVersion = lib.mkForce "25.05";
      };

      sops.age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";

      targets.genericLinux.enable = lib.mkForce false;
    };
}