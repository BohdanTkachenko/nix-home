{ config, ... }:
{
  sops.secrets.ssh_private_config = {
    sopsFile = ./private-ssh-config;
    format = "binary";
  };

  programs.ssh = {
    enable = true;

    matchBlocks."*" = {
      identityAgent = "~/.1password/agent.sock";
    };

    includes = [
      config.sops.secrets.ssh_private_config.path
    ];
  };

  home.file.".ssh/authorized_keys".source = ./authorized_keys;
}
