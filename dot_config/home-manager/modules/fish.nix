{ pkgs, ... }:

{
  programs.fish = {
    enable = true;

    shellInit = ''
      if test -e /nix/var/nix/profiles/default/etc/profile.d/nix.fish
        source /nix/var/nix/profiles/default/etc/profile.d/nix.fish
      end
    '';
  };
}