# Base NixOS configuration shared across all machines
{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ../overlays
    ./desktop.nix
    ./minecraft.nix
    ./podman.nix
    ./security.nix
    ./steam.nix
    ./user.nix
  ];

  # NixOS release version
  system.stateVersion = "25.11";

  # Nix settings
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
      trusted-users = [
        "root"
        "@wheel"
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  nixpkgs.config.allowUnfree = true;

  boot = {
    loader = {
      systemd-boot = {
        enable = lib.mkForce false;
        configurationLimit = 20;
      };
      efi.canTouchEfiVariables = true;
      timeout = 0;
    };

    lanzaboote = {
      enable = true;
      pkiBundle = "/etc/secureboot";
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
    initrd.systemd.enable = true;
    initrd.systemd.tpm2.enable = true;
    initrd.luks.devices.cryptroot.crypttabExtraOpts = [ "tpm2-device=auto" ];
    kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "udev.log_priority=3"
      "rd.systemd.show_status=auto"
    ];
  };

  networking = {
    networkmanager.enable = true;
    firewall.enable = true;
    useDHCP = lib.mkDefault true;
  };

  time.timeZone = "America/New_York";
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
  };

  console = {
    keyMap = "us";
  };

  environment.systemPackages = with pkgs; [
    bash
    curl
    firefox
    fish
    git
    htop
    jj
    sbctl
    tmux
    vim
    wget
    androidenv.androidPkgs.platform-tools
  ];

  services.fwupd.enable = true;

  # Android Debug Bridge
  programs.adb.enable = true;

  # Disable NixOS xremap (using home-manager xremap instead)
  services.xremap.enable = false;

  # SOPS secrets
  sops.age.keyFile = "${config.users.users.dan.home}/.config/sops/age/keys.txt";

  environment.variables.EDITOR = "micro";
}
