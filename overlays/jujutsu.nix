{ pkgs-unstable, isWork, ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      jujutsu =
        if isWork then
          final.writeScriptBin "jj" ''
            #!/bin/sh
            exec /usr/bin/jj "$@"
          ''
        else
          pkgs-unstable.jujutsu;
    })
  ];
}
