{ config, pkgs, ... }:
let
  nixPkg = if config.nix.package == null then pkgs.nix else config.nix.package;
  profileDirectory = config.home.profileDirectory;
in
{
  # TODO: remove when/if https://github.com/nix-community/home-manager/pull/7949 is merged.
  xdg.configFile."systemd/user-environment-generators/05-home-manager.sh" = {
    text = ''
      . "${nixPkg}/etc/profile.d/nix.sh"
      . "${profileDirectory}/etc/profile.d/hm-session-vars.sh"
    '';
    executable = true;
    force = true;
  };
}
