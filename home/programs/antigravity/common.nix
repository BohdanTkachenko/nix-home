{ config, pkgs, ... }:
{
  imports = [ ../ai/permissions.nix ];

  anti-drift.files = {
    ".gemini/config/config.json" = {
      source = (pkgs.formats.json { }).generate "gemini-config.json" {
        userSettings = {
          browserJsExecutionPolicy = "BROWSER_JS_EXECUTION_POLICY_ALWAYS_ASK";
          globalPermissionGrants = {
            allow = config.lib.permissions.forAntigravity;
          };
          useAiCredits = false;
          verboseAgentChat = true;
        };
      };
      json = true;
    };
  };
}
