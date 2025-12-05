{ ... }:
{
  imports = [ ./common.nix ];
  programs.ssh.extraConfig = ''
    Host *
      IdentityAgent ~/.1password/agent.sock
  '';
}
