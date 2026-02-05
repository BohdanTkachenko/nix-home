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
    "cat"
    "echo"
    "eza"
    "jj describe"
    "jj diff"
    "jj log"
    "jj show"
    "jj status"
    "jj write-current-commit-message-to-tmp-file"
    "ls"
    "mktemp"
  ];
in
{
  programs.gemini-cli.enable = true;

  # Flake has a default value for this option and it is persisting it into
  # sessionVariables which requires reboot or re-login to change it.
  # For Gemini CLI this env variable takes precedence over a config file.
  # This makes it impossible to specify the model using config.
  # Setting this to an empty value allows Gemini CLI to look into the config
  # instead.
  programs.gemini-cli.defaultModel = "";

  programs.gemini-cli.settings =
    lib.recursiveUpdate
      {
        general.preferredEditor = "vim";
        general.previewFeatures = true;
        ide.enabled = true;
        ide.hasSeenNudge = true;
        security.auth.selectedType = "oauth-personal";
        security.enablePermanentToolApproval = true;
        tools.allowed = allowedShellCommands;
        tools.autoAccept = true;
        tools.shell.pager = lib.getExe pkgs.bat;
        tools.shell.showColor = true;
        ui.theme = "Atom One";
      }
      (
        lib.optionalAttrs (!isWork) {
          general.disableAutoUpdate = true;
          general.disableUpdateNags = true;
          privacy.usageStatisticsEnabled = false;
        }
      );

  programs.gemini-cli.commands.commit = {
    description = "Generates a Jujutsu commit based on diff and an optional user input.";
    prompt = ''
      # Task: Generate a Jujutsu commit based on diff and an optional user input.

      ## Context

      !{TMP_FILE=$(jj write-current-commit-message-to-tmp-file) && echo "Current commit message was extracted to a temporary file: $TMP_FILE"}

      ### Current commit description and changes in current revision:

      ```
      !{jj show --ignore-all-space --no-pager}
      ```

      ### Recent commits

      ```
      !{jj log --no-graph --limit 5 --no-pager}
      ```

      ## Task

      Based on the changes above create a single atomic Jujutsu commit with a descriptive message.

      The user may provide additional instructions or context for the commit message. If it is not empty, you MUST incorporate its content into the generated commit message to reflect the user's specific requests. The user's raw command is appended below your instructions.

      This is intended as a low effort way for the user to commit so avoid asking user questions unless further clarificatation is required.

      ## Behavior

      **IMPORTANT NOTE: NEVER ask user for the confirmation. Just perform actions below.**

      1. Generate the new commit message based on the diff, log and any additional user instructions and overwrite file !{echo $TMP_FILE} with this commit message.
      2. Run the following command to apply the new message: `cat !{echo $TMP_FILE} | jj describe --stdin`
      3. Run the following command to create a new commit: `jj new`
    '';
  };
}
