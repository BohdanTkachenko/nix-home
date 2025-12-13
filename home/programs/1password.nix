{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.packages = [ (config.lib.nixGL.wrap pkgs._1password-gui) ];

  programs.ssh.extraConfig = lib.mkIf (config.custom.profile == "personal") ''
    Host *
      IdentityAgent ~/.1password/agent.sock
  '';
}
