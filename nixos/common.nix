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
    ./ollama.nix
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
        configurationLimit = lib.mkDefault 20;
      };
      efi.canTouchEfiVariables = true;
      timeout = lib.mkDefault 0;
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
  sops.age.sshKeyPaths = [ "${config.users.users.dan.home}/.ssh/id_ed25519" ];

  environment.variables.EDITOR = "micro";

  # Disable Avahi printer discovery to avoid duplicates with declarative printers
  services.avahi.enable = false;

  # Printing
  services.printing = {
    enable = true;
    browsed.enable = false;
  };

  systemd.services.ensure-printers = {
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    script = lib.mkForce ''
      # Configure each printer independently so one failure doesn't block the others
      FAILED=0
      ${pkgs.cups}/bin/lpadmin -p Brother-MFC-L3750CDW -v ipp://10.0.0.151/ipp/print -m everywhere -L Network -o PageSize=Letter -E || FAILED=1
      ${pkgs.cups}/bin/lpadmin -p Brother-QL-1110NWB -v ipp://10.0.0.152/ipp/print -m everywhere -L Network -o PageSize=4x6 -o CutMedia=EndOfPage -E || FAILED=1
      ${pkgs.cups}/bin/lpadmin -d Brother-MFC-L3750CDW
      exit $FAILED
    '';
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "30s";
    };
    startLimitBurst = 5;
    startLimitIntervalSec = 300;
  };

  hardware.printers = {
    ensurePrinters = [
      {
        name = "Brother-MFC-L3750CDW";
        location = "Network";
        deviceUri = "ipp://10.0.0.151/ipp/print";
        model = "everywhere";
        ppdOptions.PageSize = "Letter";
      }
      {
        name = "Brother-QL-1110NWB";
        location = "Network";
        deviceUri = "ipp://10.0.0.152/ipp/print";
        model = "everywhere";
        ppdOptions = {
          PageSize = "4x6";
          CutMedia = "EndOfPage";
        };
      }
    ];
    ensureDefaultPrinter = "Brother-MFC-L3750CDW";
  };
}
