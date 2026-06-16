{
  inputs,
  system,
  config,
  lib,
  pkgs,
  ...
}:
let
  mkConf = lib.generators.toKeyValue {
    mkKeyValue = lib.generators.mkKeyValueDefault {
      mkValueString = v: ''"${toString v}"'';
    } "=";
  };

  # Non-secret winapps.conf fields. RDP_PASS is injected by confText below so
  # the password never appears in this public repo.
  confSettings = {
    RDP_USER = "dan";
    RDP_DOMAIN = "";
    RDP_IP = "127.0.0.1";
    WAFLAVOR = "manual";
    RDP_SCALE = "180";
    REMOVABLE_MEDIA = "/run/media";
    RDP_FLAGS = "/cert:tofu /sound /microphone +home-drive";
    DEBUG = "true";
    AUTOPAUSE = "on";
    AUTOPAUSE_TIME = "300";
    FREERDP_COMMAND = "";
    PORT_TIMEOUT = "5";
    RDP_TIMEOUT = "30";
    APP_SCAN_TIMEOUT = "60";
    BOOT_TIMEOUT = "120";
  };
in
{
  options.my.winapps = {
    # winapps.enable is declared in home/modules/options.nix.

    # Path to a podman EnvironmentFile defining PASSWORD=<rdp password>.
    # Supplied by the private overlay (sops-rendered); null on a public build.
    envFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "EnvironmentFile providing the WinApps RDP PASSWORD for the podman container.";
    };
  };

  config = lib.mkMerge [
    {
      # Builder for the full winapps.conf, given the RDP password. The private
      # overlay calls this inside a sops.template so the rendered conf (with the
      # real password) is written to ~/.config/winapps/winapps.conf at
      # activation. Kept out of the enable gate so the overlay can reference it.
      lib.winapps.confText = rdpPass: mkConf (confSettings // { RDP_PASS = rdpPass; });
    }

    (lib.mkIf config.my.winapps.enable {
      home.packages = [
        pkgs.gnome-connections
        inputs.winapps.packages."${system}".winapps
        inputs.winapps.packages."${system}".winapps-launcher
      ];

      services.podman = {
      enable = true;

      containers.WinApps = {
        image = "ghcr.io/dockur/windows:latest";
        autoStart = true;

        environment = {
          VERSION = "11";
          RAM_SIZE = "4G";
          CPU_CORES = "4";
          DISK_SIZE = "64G";
          USERNAME = "dan";
          HOME = config.home.homeDirectory;
        };

        environmentFile = lib.optional (config.my.winapps.envFile != null) config.my.winapps.envFile;

        ports = [
          "8006:8006"
          "3389:3389/tcp"
          "3389:3389/udp"
        ];

        volumes = [
          "windows:/storage"
          "${config.home.homeDirectory}/Public:/shared"
          "${inputs.winapps.outPath}/oem:/oem:ro"
        ];

        addCapabilities = [
          "NET_ADMIN"
          "NET_RAW"
        ];

        devices = [
          "/dev/kvm"
          "/dev/net/tun"
          "/dev/bus/usb"
        ];

        extraPodmanArgs = [
          "--stop-timeout=120"
          "--group-add=keep-groups"
        ];

        extraConfig = {
          Service = {
            TimeoutStopSec = 120;
          };
        };
      };
    };
    })
  ];
}
