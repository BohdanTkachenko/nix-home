# User configuration and Home Manager setup
{
  pkgs,
  lib,
  config,
  ...
}:

let
  # Shared settings for all users
  sharedGroups = [
    "wheel"
    "networkmanager"
    "video"
    "audio"
    "input"
    "tss"
    "adbusers"
  ];
  sharedHomeImports = [
    ../home/common.nix
    ../home/personal.nix
  ];
  primaryUser = builtins.head (builtins.attrNames config.my.users);
in
{
  options.my.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          description = lib.mkOption { type = lib.types.str; };
          sshKeys = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
          };
        };
      }
    );
    default = { };
  };

  config.my.users.dan = {
    description = "Dan";
    sshKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF8dbeUB1k/CnmuFIAaZW7Avp+hqz22DxY9pMtwFQDBb"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMRn3eyTO+PNubD7oM4+5p6oxsTM5I7nKiuHZStc2AE+"
    ];
  };

  config.my.users.maria = {
    description = "Maria";
  };

  config.users.users = lib.mapAttrs (name: cfg: {
    isNormalUser = true;
    description = cfg.description;
    extraGroups = sharedGroups;
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = cfg.sshKeys;
  }) config.my.users;

  config.programs.fish.enable = true;
  config.home-manager.useUserPackages = true;

  config.home-manager.users = lib.mapAttrs (
    name: _:
    { config, lib, ... }:
    {
      imports = sharedHomeImports;
      home = {
        username = lib.mkForce name;
        homeDirectory = lib.mkForce "/home/${name}";
        stateVersion = lib.mkForce "25.11";
      };
      sops.age.sshKeyPaths = lib.mkForce [ "/home/${primaryUser}/.ssh/id_ed25519" ];
      targets.genericLinux.enable = lib.mkForce false;
    }
  ) config.my.users;
}
