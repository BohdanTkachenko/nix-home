# On-demand Cloudflare tunnel launcher.
#
# `cloudflared` is installed permanently, but no tunnel runs until you invoke
# `cf-tunnel <subdomain> <port>`. That command brings up
# https://<subdomain>.<domain> in front of http://localhost:<port> and stays up
# until interrupted (Ctrl-C), then tears down.
#
# All sensitive material — the base domain, the reused `nix` tunnel's
# credentials, and the account origin cert — lives encrypted in
# ./secrets/cloudflared.yaml and is decrypted to a tmpfs-style temp dir only for
# the lifetime of a run, using the invoking user's age key (~/.config/sops/age/
# keys.txt, materialised by the home-manager activation). Nothing is written to
# the world-readable Nix store in plaintext, and sops-nix never places it on
# disk.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.cloudflared;

  cfTunnel = pkgs.writeShellApplication {
    name = "cf-tunnel";
    runtimeInputs = [
      pkgs.cloudflared
      pkgs.sops
      pkgs.coreutils
    ];
    text = ''
      set -euo pipefail

      if [ "$#" -ne 2 ]; then
        cat >&2 <<'USAGE'
      usage: cf-tunnel <subdomain> <port>

        Brings up  https://<subdomain>.<domain>  ->  http://localhost:<port>
        Runs until interrupted (Ctrl-C).

        e.g.  cf-tunnel demo 8188
      USAGE
        exit 1
      fi

      sub=$1
      port=$2

      case "$port" in
        "" | *[!0-9]*)
          echo "cf-tunnel: port must be a number, got '$port'" >&2
          exit 1
          ;;
      esac

      secret=${./secrets/cloudflared.yaml}

      work=$(mktemp -d)
      trap 'rm -rf "$work"' EXIT

      domain=$(sops -d --extract '["domain"]' "$secret")
      tunnel_id=$(sops -d --extract '["tunnel_id"]' "$secret")
      sops -d --extract '["credentials_b64"]' "$secret" | base64 -d > "$work/cred.json"
      sops -d --extract '["cert_b64"]' "$secret" | base64 -d > "$work/cert.pem"
      chmod 600 "$work/cred.json" "$work/cert.pem"

      host="$sub.$domain"
      export TUNNEL_ORIGIN_CERT="$work/cert.pem"

      echo "cf-tunnel: routing $host -> tunnel $tunnel_id" >&2
      cloudflared tunnel route dns --overwrite-dns "$tunnel_id" "$host"

      echo "" >&2
      echo "  ▸ https://$host  ->  http://127.0.0.1:$port" >&2
      echo "  ▸ Ctrl-C to stop" >&2
      echo "" >&2

      # Foreground (no exec) so the EXIT trap still scrubs the temp creds when
      # cloudflared exits on Ctrl-C.
      #
      # Target 127.0.0.1 rather than localhost: cloudflared resolves localhost
      # to IPv6 [::1] first, so an IPv4-only origin (the common case for dev
      # servers bound to 127.0.0.1) would refuse the connection even while up.
      cloudflared tunnel run \
        --cred-file "$work/cred.json" \
        --url "http://127.0.0.1:$port" \
        "$tunnel_id"
    '';
  };
in
{
  options.my.cloudflared.enable =
    lib.mkEnableOption "on-demand Cloudflare tunnel launcher (cf-tunnel)";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.cloudflared
      cfTunnel
    ];
  };
}
