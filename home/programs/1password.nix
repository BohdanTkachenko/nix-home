{
  config,
  isWork,
  lib,
  pkgs,
  ...
}:
{
  home.packages = [ (config.lib.nixGL.wrap pkgs._1password-gui) ];

  programs.ssh.extraConfig = lib.mkIf (!isWork) ''
    Host *
      IdentityAgent ~/.1password/agent.sock
  '';
}
