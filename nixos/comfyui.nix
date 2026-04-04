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
  comfyPort = 8188;
  dataDir = "/var/lib/comfyui";
in
{
  options.my.comfyui = {
    enable = lib.mkEnableOption "ComfyUI (ROCm) via podman/oci-containers";

    image = lib.mkOption {
      type = lib.types.str;
      # yanwk/comfyui-boot:rocm — PyTorch-based ROCm variant, actively maintained
      # (yanwk publishes ~weekly). Pinned by manifest digest for reproducibility.
      # To refresh: `podman pull docker.io/yanwk/comfyui-boot:rocm` then
      # `podman inspect ... --format '{{range .RepoDigests}}{{println .}}{{end}}'`
      default = "docker.io/yanwk/comfyui-boot@sha256:85274b2fb1428039e73eada25b6f8a4b40a813b5252711dd67dcc473feca6bf0";
      description = "ROCm ComfyUI container image, pinned by digest.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Host-side persistent data dirs. The yanwk image runs as root inside the
    # container; host bind-mounts inherit that ownership.
    systemd.tmpfiles.rules = [
      "d ${dataDir}              0755 root root -"
      "d ${dataDir}/models       0755 root root -"
      "d ${dataDir}/input        0755 root root -"
      "d ${dataDir}/output       0755 root root -"
      "d ${dataDir}/custom_nodes 0755 root root -"
    ];

    virtualisation.oci-containers.containers.comfyui = {
      image = cfg.image;
      autoStart = true;

      volumes = [
        "${dataDir}/models:/root/ComfyUI/models"
        "${dataDir}/input:/root/ComfyUI/input"
        "${dataDir}/output:/root/ComfyUI/output"
        "${dataDir}/custom_nodes:/root/ComfyUI/custom_nodes"
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
      ];
    };

    # LAN-only access to ComfyUI. Concatenated onto any other extraCommands
    # strings (e.g. from ollama.nix) via NixOS module merging.
    networking.firewall.extraCommands = ''
      iptables -A nixos-fw -p tcp -s ${lanCidr} --dport ${toString comfyPort} -j nixos-fw-accept
    '';
    networking.firewall.extraStopCommands = ''
      iptables -D nixos-fw -p tcp -s ${lanCidr} --dport ${toString comfyPort} -j nixos-fw-accept 2>/dev/null || true
    '';
  };
}
