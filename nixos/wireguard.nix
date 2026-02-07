{ config, ... }:
{
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
        endpoint = "$WG_HOME_ENDPOINT:51820";
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
        endpoint = "$WG_GCP_GAMING_SC_ENDPOINT:51820";
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
        endpoint = "$WG_AWS_GAMING_VA_ENDPOINT:51820";
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
        endpoint = "$WG_PROTON_IL_ENDPOINT:51820";
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
        endpoint = "$WG_PROTON_NJ_ENDPOINT:51820";
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
        endpoint = "$WG_PROTON_UA_ENDPOINT:51820";
        allowed-ips = "0.0.0.0/0; ::/0;";
      };
      ipv4 = {
        method = "manual";
        address1 = "10.2.0.2/32";
        dns = "10.2.0.1;";
      };
    };
  };
}
