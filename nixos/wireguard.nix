{
  config,
  lib,
  ...
}:
let
  cfg = config.my.wireguard;
in
{
  options.my.wireguard = {
    enable = lib.mkEnableOption "WireGuard VPN profiles";

    # Peer endpoint IPs, set per host by the private overlay so they stay out of
    # this public repo. The private keys still come from the sops env file.
    endpoints = {
      home = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Endpoint IP for the home VPN peer.";
      };
      gcpGamingSc = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Endpoint IP for the GCP gaming (SC) VPN peer.";
      };
      awsGamingVa = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Endpoint IP for the AWS gaming (VA) VPN peer.";
      };
      protonIl = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Endpoint IP for the Proton IL VPN peer.";
      };
      protonNj = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Endpoint IP for the Proton NJ VPN peer.";
      };
      protonUa = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Endpoint IP for the Proton UA VPN peer.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.wg-env = {
      sopsFile = ./secrets/wireguard.yaml;
    };

    networking.firewall.checkReversePath = "loose";

    networking.networkmanager.ensureProfiles = {
      environmentFiles = [ config.sops.secrets.wg-env.path ];

      profiles.home-vpn = {
        connection = {
          id = "Home Network";
          type = "wireguard";
          interface-name = "wg-home";
          autoconnect = "false";
        };
        wireguard = {
          private-key = "$WG_CLOUD_PRIVATE_KEY";
          private-key-flags = "0";
        };
        "wireguard-peer.Zrm58Xr1+MSy1Z+wSaGYh8tof6NQ2Z+NlKory1FL81Q=" = {
          endpoint = "${cfg.endpoints.home}:51820";
          allowed-ips = "0.0.0.0/0;";
        };
        ipv4 = {
          method = "manual";
          address1 = "10.100.0.100/24";
          dns = "10.100.0.1;";
        };
        ipv6.method = "disabled";
      };

      profiles.gcp-gaming-sc-vpn = {
        connection = {
          id = "GCP Gaming (SC)";
          type = "wireguard";
          interface-name = "wg-gcp-sc";
          autoconnect = "false";
        };
        wireguard = {
          private-key = "$WG_CLOUD_PRIVATE_KEY";
          private-key-flags = "0";
          mtu = "1420";
        };
        "wireguard-peer.bWq3e9vp3TBtqBf+/1CF/Gk3+J31QurrOrLuyBh5Tmc=" = {
          endpoint = "${cfg.endpoints.gcpGamingSc}:51820";
          allowed-ips = "0.0.0.0/0;";
        };
        ipv4 = {
          method = "manual";
          address1 = "10.200.200.2/24";
          dns = "8.8.8.8;";
        };
        ipv6.method = "disabled";
      };

      profiles.aws-gaming-vpn = {
        connection = {
          id = "AWS Gaming (Virginia)";
          type = "wireguard";
          interface-name = "wg-aws";
          autoconnect = "false";
        };
        wireguard = {
          private-key = "$WG_CLOUD_PRIVATE_KEY";
          private-key-flags = "0";
          mtu = "1420";
        };
        "wireguard-peer.+58DCzHj8WAd3ZvImRDgHOBlTFqdXj49gJZICOpoxWs=" = {
          endpoint = "${cfg.endpoints.awsGamingVa}:51820";
          allowed-ips = "0.0.0.0/0;";
        };
        ipv4 = {
          method = "manual";
          address1 = "10.200.200.2/24";
          dns = "8.8.8.8;";
        };
        ipv6.method = "disabled";
      };

      profiles.proton-il-vpn = {
        connection = {
          id = "Proton IL";
          type = "wireguard";
          interface-name = "wg-proton-il";
          autoconnect = "false";
        };
        wireguard = {
          private-key = "$WG_PROTON_IL_PRIVATE_KEY";
          private-key-flags = "0";
        };
        "wireguard-peer.C6GJzhSJVSKXNhagTOHn587mLXnvtvOGkOi4l2tN6hs=" = {
          endpoint = "${cfg.endpoints.protonIl}:51820";
          allowed-ips = "0.0.0.0/0; ::/0;";
        };
        ipv4 = {
          method = "manual";
          address1 = "10.2.0.2/32";
          dns = "10.2.0.1;";
        };
      };

      profiles.proton-nj-vpn = {
        connection = {
          id = "Proton NJ";
          type = "wireguard";
          interface-name = "wg-proton-nj";
          autoconnect = "false";
        };
        wireguard = {
          private-key = "$WG_PROTON_NJ_PRIVATE_KEY";
          private-key-flags = "0";
        };
        "wireguard-peer./HvEnSU5JaswyBC/YFs74eGLXqLdzsaFeVT8SD1KYAc=" = {
          endpoint = "${cfg.endpoints.protonNj}:51820";
          allowed-ips = "0.0.0.0/0; ::/0;";
        };
        ipv4 = {
          method = "manual";
          address1 = "10.2.0.2/32";
          dns = "10.2.0.1;";
        };
      };

      profiles.proton-ua-vpn = {
        connection = {
          id = "Proton UA";
          type = "wireguard";
          interface-name = "wg-proton-ua";
          autoconnect = "false";
        };
        wireguard = {
          private-key = "$WG_PROTON_UA_PRIVATE_KEY";
          private-key-flags = "0";
        };
        "wireguard-peer.vx4tC7xZn44VN4dyiK0yUBHRC3/cmlwwaLuPpq3rIQg=" = {
          endpoint = "${cfg.endpoints.protonUa}:51820";
          allowed-ips = "0.0.0.0/0; ::/0;";
        };
        ipv4 = {
          method = "manual";
          address1 = "10.2.0.2/32";
          dns = "10.2.0.1;";
        };
      };
    };
  };
}
