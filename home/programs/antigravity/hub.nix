{
  pkgs,
  pkgs-antigravity-hub,
  ...
}:
let
  pinToCCD1 = import ../../../lib/pin-to-ccd1.nix { inherit pkgs; };
in
{
  home.packages = [
    (pinToCCD1 pkgs-antigravity-hub.antigravity-hub)
  ];
}
