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
    ./options.nix
    ./cloudflared.nix
    ./comfyui.nix
    ./desktop.nix
    ./minecraft.nix
    ./ollama.nix
    ./performance.nix
    ./podman.nix
    ./security.nix
    ./steam.nix
    ./user.nix
    ./waydroid.nix
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
      # mkDefault so image-based hosts (OCI) can set it false.
      efi.canTouchEfiVariables = lib.mkDefault true;
      timeout = lib.mkDefault 0;
    };

    lanzaboote = lib.mkIf config.my.secureBoot.enable {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };

    plymouth = lib.mkIf config.my.gui.enable {
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
    initrd.systemd.tpm2.enable = config.my.secureBoot.enable;
    # The cryptroot crypttab opt lives with the LUKS layout (disk-luks-btrfs.nix).
    kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "udev.log_priority=3"
      "rd.systemd.show_status=auto"
    ];
  };

  networking = {
    # NetworkManager is a desktop concern; headless hosts use systemd-networkd.
    networkmanager.enable = config.my.gui.enable;
    nftables.enable = true;
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

  environment.systemPackages =
    with pkgs;
    [
      bash
      curl
      ddcutil
      fish
      git
      htop
    ]
    ++ lib.optional config.my.gui.enable nvtopPackages.amd
    ++ [
      jj
      sbctl
      tmux
      vim
      wget
    ]
    ++ lib.optional config.my.gui.enable androidenv.androidPkgs.platform-tools
    ++ lib.optionals config.my.gui.enable [
      firefox
    ];

  # Enable i2c for ddcutil monitor control
  hardware.i2c.enable = true;

  services.fwupd.enable = true;

  # Expose binaries at /bin/* and /usr/bin/* so scripts with non-Nix shebangs
  # (e.g. `#!/bin/bash`) work without patching. Backed by FUSE, resolves to
  # whatever is on PATH.
  services.envfs.enable = true;

  # Android Debug Bridge
  programs.adb.enable = config.my.gui.enable;

  # Disable NixOS xremap (using home-manager xremap instead)
  services.xremap.enable = false;

  environment.variables.EDITOR = "micro";

  # Disable Avahi printer discovery to avoid duplicates with declarative printers
  services.avahi.enable = false;

  # Printing (declarative LAN printers — a desktop concern).
  services.printing = lib.mkIf config.my.gui.enable {
    enable = true;
    browsed.enable = false;
  };

  systemd.services.ensure-printers = lib.mkIf config.my.gui.enable {
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

  hardware.printers = lib.mkIf config.my.gui.enable {
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
