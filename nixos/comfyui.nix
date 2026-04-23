# ComfyUI (ROCm) via podman/oci-containers, LAN-exposed for tesseract
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.comfyui;
  lanCidr = "10.0.0.0/8";
  lanPort = 8188;
  upstreamPort = 18188;
  dataDir = cfg.dataDir;
  remap = cfg.uid != null && cfg.gid != null;
  ownerUid = if remap then toString cfg.uid else "0";
  ownerGid = if remap then toString cfg.gid else "0";
  extraPipEnabled = cfg.extraPipPackages != [ ];
  preStartScript = pkgs.writeShellScript "comfyui-pre-start" ''
    set -eu
    echo "[pre-start] ensuring extra pip packages: ${toString cfg.extraPipPackages}"
    pip install --user --no-warn-script-location ${lib.escapeShellArgs cfg.extraPipPackages}
  '';
  authEnvFile =
    if cfg.authSops then
      config.sops.templates."comfyui-auth.env".path
    else
      cfg.authEnvFile;
  authEnabled = authEnvFile != null;
  # When auth is enabled, ComfyUI binds loopback only and Caddy fronts the LAN
  # port. Without auth, ComfyUI itself binds the LAN port directly.
  comfyListen = if authEnabled then "127.0.0.1" else "0.0.0.0";
  comfyPort = if authEnabled then upstreamPort else lanPort;
  caddyfile = pkgs.writeText "comfyui-Caddyfile" ''
    {
      admin off
      auto_https off
    }
    :${toString lanPort} {
      basic_auth {
        {$COMFYUI_AUTH_USER} {$COMFYUI_AUTH_HASH}
      }
      reverse_proxy 127.0.0.1:${toString upstreamPort}
    }
  '';
in
{
  options.my.comfyui = {
    enable = lib.mkEnableOption "ComfyUI (ROCm) via podman/oci-containers";

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/comfyui";
      description = ''
        Host directory holding ComfyUI's persistent data
        (`models/`, `input/`, `output/`, `custom_nodes/`).
      '';
    };

    uid = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      example = 1000;
      description = ''
        Host UID that should own the data directory and to which the
        container's root user is remapped via podman uidmap. When set
        together with `gid`, files written by ComfyUI inside the
        container appear on the host as this user — letting you browse
        and drop files in via your file manager. When null, container
        runs as host root (legacy behavior).
      '';
    };

    gid = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      example = 100;
      description = "Host GID counterpart to `uid`.";
    };

    extraPipPackages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "onnxruntime" "insightface" ];
      description = ''
        Extra Python packages to `pip install --user` inside the
        ComfyUI container on every start. Installs land in
        `${dataDir}/.local` (bind-mounted), so they persist across
        container restarts/recreates and get re-checked (no-op when
        already up to date) on each boot.
      '';
    };

    image = lib.mkOption {
      type = lib.types.str;
      # yanwk/comfyui-boot:rocm — PyTorch-based ROCm variant, actively maintained
      # (yanwk publishes ~weekly). Pinned by manifest digest for reproducibility.
      # To refresh: `podman pull docker.io/yanwk/comfyui-boot:rocm` then
      # `podman inspect ... --format '{{range .RepoDigests}}{{println .}}{{end}}'`
      default = "docker.io/yanwk/comfyui-boot@sha256:85274b2fb1428039e73eada25b6f8a4b40a813b5252711dd67dcc473feca6bf0";
      description = "ROCm ComfyUI container image, pinned by digest.";
    };

    authEnvFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = "/run/secrets/comfyui-auth";
      description = ''
        Path to a systemd EnvironmentFile providing HTTP basic-auth
        credentials for the Caddy reverse proxy. Must define:

          COMFYUI_AUTH_USER=<username>
          COMFYUI_AUTH_HASH=<bcrypt hash from `caddy hash-password`>

        When set (or when `authSops` is true), ComfyUI is moved to
        loopback-only and Caddy fronts the LAN port with basic auth.
        Otherwise ComfyUI is exposed to the LAN unauthenticated.

        Ignored when `authSops` is true.
      '';
    };

    authSops = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Pull basic-auth credentials from the sops-encrypted YAML at
        `nixos/secrets/comfyui-auth.yaml` (keys `COMFYUI_AUTH_USER` and
        `COMFYUI_AUTH_HASH`). A dotenv EnvironmentFile is rendered via
        sops.templates and passed to Caddy. Overrides `authEnvFile`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Host-side persistent data dirs. When uid/gid are set, the container's
    # root is remapped to this host user (see extraOptions below), so files
    # the container writes appear owned by the host user on disk.
    systemd.tmpfiles.rules = [
      "d ${dataDir}              0755 ${ownerUid} ${ownerGid} -"
      "d ${dataDir}/models       0755 ${ownerUid} ${ownerGid} -"
      "d ${dataDir}/input        0755 ${ownerUid} ${ownerGid} -"
      "d ${dataDir}/output       0755 ${ownerUid} ${ownerGid} -"
      "d ${dataDir}/custom_nodes 0755 ${ownerUid} ${ownerGid} -"
    ]
    ++ lib.optionals extraPipEnabled [
      "d ${dataDir}/.local       0755 ${ownerUid} ${ownerGid} -"
      "d ${dataDir}/.cache       0755 ${ownerUid} ${ownerGid} -"
      "d ${dataDir}/user-scripts 0755 ${ownerUid} ${ownerGid} -"
    ];

    virtualisation.oci-containers.containers.comfyui = {
      image = cfg.image;
      autoStart = true;

      environment = {
        CLI_ARGS = "--listen ${comfyListen} --port ${toString comfyPort}";
      };

      volumes = [
        "${dataDir}/models:/root/ComfyUI/models"
        "${dataDir}/input:/root/ComfyUI/input"
        "${dataDir}/output:/root/ComfyUI/output"
        "${dataDir}/custom_nodes:/root/ComfyUI/custom_nodes"
      ]
      ++ lib.optionals extraPipEnabled [
        # /root/.local persists `pip install --user` packages across recreates.
        # /root/.cache persists pip's wheel/HTTP cache for fast re-checks.
        # /root/user-scripts holds the auto-generated pre-start.sh hook.
        "${dataDir}/.local:/root/.local"
        "${dataDir}/.cache:/root/.cache"
        "${dataDir}/user-scripts:/root/user-scripts"
      ];

      # Use host networking so the LAN-only `nixos-fw` rules below actually
      # apply. Published ports via `ports = [...]` would go through podman's
      # DNAT (PREROUTING/FORWARD chains) and bypass `nixos-fw` (INPUT),
      # making the port unrestricted on 0.0.0.0. Host networking keeps the
      # bind on the host stack where `nixos-fw` sees the traffic normally.
      # The container runs as root internally (openSUSE Tumbleweed base image),
      # and /dev/kfd + /dev/dri/renderD128 are mode 0666 on the host, so we
      # don't need --group-add for device access. (And --group-add=render by
      # name fails under podman's NSS lookup on NixOS even though the group
      # exists — numeric GIDs work but are brittle.)
      extraOptions = [
        "--network=host"
        "--device=/dev/kfd"
        "--device=/dev/dri"
        "--ipc=host"
        "--security-opt=seccomp=unconfined"
      ]
      # When uid/gid are set, remap container root → that host user so
      # bind-mounted models/input/output/custom_nodes are owned by the user
      # on the host and writable from a file manager. Other container UIDs
      # fall into the subuid range allocated by nixos/podman.nix.
      ++ lib.optionals remap [
        "--uidmap=0:${toString cfg.uid}:1"
        "--uidmap=1:100000:65535"
        "--gidmap=0:${toString cfg.gid}:1"
        "--gidmap=1:100000:65535"
      ];
    };

    # LAN-only access to whatever is bound on lanPort (Caddy when auth is
    # enabled, ComfyUI directly otherwise).
    networking.firewall.extraInputRules = ''
      ip saddr ${lanCidr} tcp dport ${toString lanPort} accept
    '';

    # Caddy as an oci-container rather than the NixOS service module: keeps the
    # whole ComfyUI stack in podman, avoids a system-level service whose only
    # job is to front this one container, and sidesteps the
    # caddy.service-fails-on-boot loop when the sops EnvironmentFile isn't
    # ready yet (podman waits for podman.socket, which comes up later).
    virtualisation.oci-containers.containers.comfyui-caddy = lib.mkIf authEnabled {
      # Pin by digest like the comfyui image. To refresh:
      #   podman pull docker.io/caddy:2-alpine
      #   podman inspect docker.io/caddy:2-alpine --format '{{range .RepoDigests}}{{println .}}{{end}}'
      image = "docker.io/caddy:2-alpine";
      autoStart = true;
      environmentFiles = [ authEnvFile ];
      volumes = [
        "${caddyfile}:/etc/caddy/Caddyfile:ro"
      ];
      # Host networking so the bind on lanPort hits the host stack and our
      # nixos-fw LAN rule applies (same reason as the comfyui container).
      extraOptions = [ "--network=host" ];
    };

    # Sync the nix-built pre-start hook into the host user-scripts dir so the
    # container reads the current version (and can chmod it, since the dest
    # lives on a regular host filesystem rather than the read-only nix store).
    systemd.services.podman-comfyui = lib.mkIf extraPipEnabled {
      serviceConfig.ExecStartPre = [
        "${pkgs.coreutils}/bin/install -D -m 0755 -o ${ownerUid} -g ${ownerGid} ${preStartScript} ${dataDir}/user-scripts/pre-start.sh"
      ];
    };

    sops = lib.mkIf cfg.authSops {
      secrets."COMFYUI_AUTH_USER" = {
        sopsFile = ./secrets/comfyui-auth.yaml;
      };
      secrets."COMFYUI_AUTH_HASH" = {
        sopsFile = ./secrets/comfyui-auth.yaml;
      };
      templates."comfyui-auth.env".content = ''
        COMFYUI_AUTH_USER=${config.sops.placeholder."COMFYUI_AUTH_USER"}
        COMFYUI_AUTH_HASH=${config.sops.placeholder."COMFYUI_AUTH_HASH"}
      '';
    };
  };
}
