{ config, lib, ... }:
{
  programs.direnv = {
    enable = true;
    silent = true;
    nix-direnv.enable = true;
  };

  programs.direnv-instant.enable = lib.mkIf config.my.direnv-instant.enable true;
}
