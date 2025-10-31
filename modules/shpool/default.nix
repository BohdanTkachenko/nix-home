{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.shpool;
  shpool-auto-attach = pkgs.writeShellApplication {
    name = "shpool-auto-attach";
    runtimeInputs =
      with pkgs;
      [
        coreutils
        gawk
      ]
      ++ lib.optional (!cfg.useSystemBinary) pkgs.shpool;
    text = builtins.readFile ./shpool-auto-attach.sh;
  };
in
{
  options.custom.shpool = {
    useSystemBinary = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to use the system-provided shpool binary instead of the one from Nixpkgs.";
    };
  };

  config = {
    home.packages = [ shpool-auto-attach ];
  };
}
