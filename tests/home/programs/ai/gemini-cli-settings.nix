# Tests for gemini-cli mutable settings via anti-drift module
{ self, lib }:
let
  config = self.nixosConfigurations.nyancat.config.home-manager.users.dan;

  antiDriftFiles = config.anti-drift.files;
  antiDriftScript = config.home.activation.antiDrift.data or "";
in
{
  # anti-drift auto-disables home.file entries
  gemini-settings-symlink-disabled = {
    expr = config.home.file.".gemini/settings.json".enable;
    expected = false;
  };

  gemini-policy-symlink-disabled = {
    expr = config.home.file.".gemini/policies/nix.toml".enable;
    expected = false;
  };

  # anti-drift.files has both entries
  gemini-settings-anti-drift-entry = {
    expr = antiDriftFiles ? ".gemini/settings.json";
    expected = true;
  };

  gemini-policy-anti-drift-entry = {
    expr = antiDriftFiles ? ".gemini/policies/nix.toml";
    expected = true;
  };

  # JSON flag set correctly
  gemini-settings-json-flag = {
    expr = antiDriftFiles.".gemini/settings.json".json;
    expected = true;
  };

  gemini-policy-json-flag = {
    expr = antiDriftFiles.".gemini/policies/nix.toml".json;
    expected = false;
  };

  # antiDrift script uses expected tools
  anti-drift-uses-jq = {
    expr = lib.hasInfix "jq" antiDriftScript;
    expected = true;
  };

  anti-drift-uses-sort-keys = {
    expr = lib.hasInfix "--sort-keys" antiDriftScript;
    expected = true;
  };

  anti-drift-uses-diff = {
    expr = lib.hasInfix "diff" antiDriftScript;
    expected = true;
  };

  anti-drift-sets-writable = {
    expr = lib.hasInfix "chmod 644" antiDriftScript;
    expected = true;
  };

  anti-drift-exits-on-drift = {
    expr = lib.hasInfix "exit 1" antiDriftScript;
    expected = true;
  };
}
