{pkgs, ...}:{
  environment.systemPackages = with pkgs; [
    prismlauncher
  ];

  networking.firewall = {
    allowedTCPPorts = [ 25565 ];
    allowedUDPPorts = [ 19132 ];
  };
}