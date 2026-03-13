{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.packages = [ (config.lib.nixGL.wrap pkgs._1password-gui) ];

  programs.ssh.extraConfig = lib.mkIf (!config.my.google.enable) ''
    Host *
      IdentityAgent ~/.1password/agent.sock
  '';
}
