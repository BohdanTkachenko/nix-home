{ ... }:
{
  config.custom.shpool.useSystemBinary = true;

  imports = [
    ./cli.nix
    ../modules/ssh/work.nix
  ];
}
