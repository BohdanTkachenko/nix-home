{ pkgs, ... }:
{
  anti-drift.files = {
    ".gemini/config/config.json" = {
      source = (pkgs.formats.json { }).generate "gemini-config.json" {
        userSettings = {
          browserJsExecutionPolicy = "BROWSER_JS_EXECUTION_POLICY_ALWAYS_ASK";
          globalPermissionGrants = {
            allow = [
              "command(ls)"
              "command(head)"
              "command(find)"
              "command(jj status)"
              "command(jj log)"
              "command(jj bookmark)"
              "command(jj diff)"
              "command(jj show)"
              "command(git show-ref)"
              "command(grep)"
              "command(git branch)"
              "command(jj --version)"
              "read_url(raw.githubusercontent.com)"
              "command(git add)"
              "command(cd)"
              "command(cat)"
            ];
          };
          useAiCredits = false;
          verboseAgentChat = true;
        };
      };
      json = true;
    };
  };
}
