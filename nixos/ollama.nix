# Ollama LLM server, LAN-exposed for Open WebUI on tesseract
{
  config,
  lib,
  pkgs-master,
  ...
}:
let
  cfg = config.my.ollama;
  # RFC1918 10/8 covers both 10.0.0.0/24 (nyancat's enp7s0) and
  # 10.42.0.0/16 (tesseract). Do NOT widen beyond RFC1918.
  lanCidr = "10.0.0.0/8";
in
{
  options.my.ollama = {
    enable = lib.mkEnableOption "Ollama LLM server, LAN-exposed";

    extraLoadModels = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Additional models to pre-pull beyond the defaults.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.ollama = {
      enable = true;
      package = pkgs-master.ollama-rocm;
      host = "0.0.0.0";
      port = 11434;
      acceleration = "rocm";
      # LAN-only firewall rules are added below; don't let the upstream
      # module open 11434 to all sources.
      openFirewall = false;

      loadModels = [
        "llama3.1:8b"
        "qwen2.5-coder:7b"
        "nomic-embed-text"
        "qwen2.5:32b-instruct-q4_K_M"
      ]
      ++ cfg.extraLoadModels;
    };

    # LAN-only access to Ollama's HTTP API. The nixos-fw chain is rebuilt
    # from scratch on every firewall reload, so appending here is safe and
    # lands before the terminal -j nixos-fw-log-refuse.
    networking.firewall.extraCommands = ''
      iptables -A nixos-fw -p tcp -s ${lanCidr} --dport 11434 -j nixos-fw-accept
    '';
    networking.firewall.extraStopCommands = ''
      iptables -D nixos-fw -p tcp -s ${lanCidr} --dport 11434 -j nixos-fw-accept 2>/dev/null || true
    '';
  };
}
