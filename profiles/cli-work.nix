{ ... }:
{
  config.custom.shpool.useSystemBinary = true;

  imports = [
    ./cli.nix
    ../modules/fish/work.nix
    ../modules/ssh/work.nix
  ];
}
