{
  pkgs,
  pkgs-master,
  ...
}:
let
  pinToCCD1 = import ../../../lib/pin-to-ccd1.nix { inherit pkgs; };
in
{
  home.packages = [
    (pinToCCD1 pkgs-master.antigravity-cli)
  ];

  anti-drift.files = {
    ".gemini/antigravity-cli/settings.json" = {
      json = true;
      preserve = [ "trustedWorkspaces" ];
      source = (pkgs.formats.json { }).generate "antigravity-cli-settings.json" {
        colorScheme = "dark";
        enableTelemetry = false;
      };
    };
  };
}
