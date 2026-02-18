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
in
{
  home.packages = [
    pkgs.gnome-connections
    inputs.winapps.packages."${system}".winapps
    inputs.winapps.packages."${system}".winapps-launcher
  ];

  sops.secrets.winapps-rdp-password = {
    sopsFile = ./secrets/winapps.yaml;
    key = "rdp_password";
  };

  sops.templates."winapps-env" = {
    content = "PASSWORD=${config.sops.placeholder.winapps-rdp-password}\n";
  };

  sops.templates."winapps.conf" = {
    content = mkConf {
      RDP_USER = "dan";
      RDP_PASS = config.sops.placeholder.winapps-rdp-password;
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
    path = "${config.home.homeDirectory}/.config/winapps/winapps.conf";
  };

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

      environmentFile = [
        config.sops.templates."winapps-env".path
      ];

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
}
