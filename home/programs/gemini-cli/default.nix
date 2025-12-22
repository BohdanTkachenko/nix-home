{
  config,
  isWork,
  isWorkPC,
  lib,
  pkgs,
  ...
}:
{
  programs.gemini-cli.enable = true;

  programs.gemini-cli.settings = {
    general.preferredEditor = "vim";
    ide.enabled = true;
    ide.hasSeenNudge = true;
    security.auth.selectedType = "oauth-personal";
    ui.accessibility.disableLoadingPhrases = true;
    ui.footer.hideSandboxStatus = true;
    ui.showCitations = true;
    ui.showLineNumbers = false;
    ui.theme = "Atom One";
  }
  // lib.optionalAttrs (!isWork) {
    general.disableAutoUpdate = true;
    general.disableUpdateNags = true;
    privacy.usageStatisticsEnabled = false;
  };

  programs.gemini-cli.commands.commit = {
    description = "Generates a Jujutsu commit message based on diff.";
    prompt = ''
      ## Context

      ### List of all changes made:

      ```
      !{jj status}
      ```

      ### Recent commits history:

      ```
      !{jj log -r "present(p4base)..@" --no-graph -n 10 -T builtin_log_detailed}
      ```

      ### Full diff:

      ```diff
      !{jj diff}
      ```
      ## Task

      Based on the changes above; create a single atomic Jujutsu commit
      with a descriptive message. Utilize Conventional Commits only if
      previous commits use them; otherwise do not use Conventional Commits.

      This is intended as a low effort way for the user to commit; so avoid
      asking user questions; unless absolutely necessary. User may ask you
      to correct the message as needed.

      Run the following two commands with the new commit message:

      ```sh
      jj describe -m "<provide your generated commit message here>" && jj new
      ```
    '';
  };
}
