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
        model.name = "gemini-3-pro-preview";
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
    description = "Generates a Jujutsu commit message based on diff.";
    prompt = ''
      ## Context

      ### Current commit description and changes in current revision:

      ```
      !{jj show --stat --git --ignore-all-space --no-pager}
      ```

      ### Recent commits

      !{jj log --no-graph --limit 5 --no-pager}

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
