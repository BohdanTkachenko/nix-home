{ config, pkgs-unstable, ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      jujutsu =
        if config.my.google.enable then
          final.writeScriptBin "jj" ''
            #!/bin/sh
            exec /usr/bin/jj "$@"
          ''
        else
          pkgs-unstable.jujutsu;
    })
  ];
}
