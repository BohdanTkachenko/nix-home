{
  config,
  pkgs,
  ...
}:
{
  home.packages = [ (config.lib.nixGL.wrap pkgs._1password-gui) ];

  programs.ssh.extraConfig = ''
    Host *
      IdentityAgent ~/.1password/agent.sock
  '';
}
