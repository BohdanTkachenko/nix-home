{ ... }:
{
  config.custom.shpool.useSystemBinary = true;

  imports = [
    ./common.nix
    ../programs/fish/work.nix
    ../programs/jujutsu/work.nix
    ../programs/ssh/work.nix
  ];
}
