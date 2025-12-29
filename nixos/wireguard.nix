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
        private-key = "$WG_PRIVATE_KEY";
        private-key-flags = "0";
      };
      "wireguard-peer.Zrm58Xr1+MSy1Z+wSaGYh8tof6NQ2Z+NlKory1FL81Q=" = {
        endpoint = "$WG_ENDPOINT:51820";
        allowed-ips = "0.0.0.0/0;";
      };
      ipv4 = {
        method = "manual";
        address1 = "10.100.0.2/24";
        dns = "10.100.0.1;";
      };
      ipv6.method = "disabled";
    };
  };
}
