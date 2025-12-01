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
      "tss"
    ];
    shell = pkgs.fish;
  };

  programs.fish.enable = true;

  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 20;
      };
      efi.canTouchEfiVariables = true;
      timeout = 0;
    };

    plymouth = {
      enable = true;
      theme = "lone";
      themePackages = with pkgs; [
        (adi1090x-plymouth-themes.override {
          selected_themes = [ "lone" ];
        })
      ];
    };

    consoleLogLevel = 3;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "udev.log_priority=3"
      "rd.systemd.show_status=auto"
    ];
  };

  security.tpm2 = {
    enable = true;
    pkcs11.enable = true;
    tctiEnvironment.enable = true;
  };

  services.displayManager.autoLogin.user = "dan";
  boot.initrd.systemd.enable = true;
  systemd.services.display-manager.serviceConfig.KeyringMode = lib.mkForce "inherit";
  security.pam.services.sddm-autologin.text = pkgs.lib.mkBefore ''
    auth optional ${pkgs.systemd}/lib/security/pam_systemd_loadkey.so
    auth include sddm
  '';

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
  
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "dan" ];
  };
}