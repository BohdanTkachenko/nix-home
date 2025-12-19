{
  pkgs-unstable,
  isWorkPC,
  isWorkLaptop,
  ...
}:
let
  customFlags =
    if isWorkPC then
      [ "--gfg" ]
    else if isWorkLaptop then
      [ "--proxy=false" ]
    else
      [ ];
in
{
  nixpkgs.overlays = [
    (final: prev: {
      gemini-cli =
        if (builtins.length customFlags) != 0 then
          (final.writeShellScriptBin "gemini" ''
            exec /google/bin/releases/gemini-cli/tools/gemini ${builtins.concatStringsSep " " customFlags} "$@"
          '')
        else
          pkgs-unstable.gemini-cli;
    })
  ];
}
