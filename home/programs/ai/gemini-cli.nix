{
  config,
  isWork,
  isWorkPC,
  lib,
  pkgs,
  ...
}:
let
  allowedShellCommands = lib.lists.map (cmd: "run_shell_command(${cmd})") [
    "jj diff"
    "jj log"
    "jj status"
    "jj show"
  ];
in
{
  programs.gemini-cli.enable = true;

  programs.gemini-cli.settings = {
    general.preferredEditor = "vim";
    ide.enabled = true;
    ide.hasSeenNudge = true;
    security.auth.selectedType = "oauth-personal";
    security.enablePermanentToolApproval = true;
    tools.allowed = allowedShellCommands;
    tools.autoAccept = true;
    tools.shell.pager = lib.getExe pkgs.bat;
    tools.shell.showColor = true;
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

      ### Current commit description and changes in current revision:

      ```
      !{jj show --stat --git --ignore-all-space}
      ```

      ### Recent commits

      !{jj log --no-graph --limit 5}

      ## Task

      Based on the changes above create a single atomic Jujutsu commit
      with a descriptive message.

      This is intended as a low effort way for the user to commit so avoid
      asking user questions unless absolutely necessary. User may ask you
      to correct the message as needed.

      Run the following two commands with the new commit message:

      ```sh
      jj describe -m "<provide your generated commit message here>" && jj new
      ```
    '';
  };
}
