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
      "adbusers"
    ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF8dbeUB1k/CnmuFIAaZW7Avp+hqz22DxY9pMtwFQDBb"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMRn3eyTO+PNubD7oM4+5p6oxsTM5I7nKiuHZStc2AE+"
    ];
  };

  programs.fish.enable = true;

  home-manager.useUserPackages = true;
  home-manager.users.dan =
    { config, lib, ... }:
    {
      imports = [
        ../home/common.nix
        ../home/personal.nix
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
