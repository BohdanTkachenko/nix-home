# Guard against accidentally rebuilding a host from the public flake when its
# complete configuration depends on the private overlay.
#
# Desktop hosts set `my.privateOverlay.required = true` (below, in flake.nix).
# The private flake's overlay sets `my.privateOverlay.present = true` via
# extendModules. Building such a host from the *public* flake therefore trips
# the assertion below and fails at evaluation with a pointer to the right
# command — instead of silently producing a system missing its private config.
#
# Servers leave `required = false`, so they keep building from the public flake
# (they carry no private config and must not depend on the private repo).
{ config, lib, ... }:
{
  options.my.privateOverlay = {
    required = lib.mkEnableOption "that this host's configuration is completed by the private overlay";
    present = lib.mkEnableOption "that the private overlay is loaded (set by the private flake)";
  };

  config.assertions = [
    {
      assertion = !config.my.privateOverlay.required || config.my.privateOverlay.present;
      message = ''
        Host '${config.networking.hostName}' requires its private overlay, but it
        is not loaded — you are building from the public flake.

        Rebuild from the private flake instead:
          cd ~/Projects/nix-home/private && nix run .#rebuild
      '';
    }
  ];
}
