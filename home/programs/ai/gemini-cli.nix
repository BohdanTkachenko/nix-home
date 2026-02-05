{
  config,
  isWork,
  isWorkPC,
  lib,
  pkgs,
  ...
}:
let
  allowedCommands = [
    "cat"
    "echo"
    "eza"
    "tee"
    "ls"
    "mktemp"
  ];
  allowedSubcommands = {
    jj = [
      "describe"
      "diff"
      "log"
      "show"
      "status"
    ];
    rm = [
      ".*.jj/tmp/jj-commit-message.*"
    ];
  };

  writeCommitMsg = lib.getExe (
    pkgs.writers.writeNuBin "write-commit-msg" ''
      let commit_id = (jj log --no-graph -r @ -T commit_id)

      let tmp_dir = ([(pwd), ".jj", "tmp"] | path join)
      mkdir $tmp_dir
      ls $tmp_dir 
      | where type == file and modified < ((date now) - 1hr) 
      | each { |it| rm $it.name }

      let tmp_file = $"($tmp_dir)/jj-commit-message.($commit_id)"

      jj log --no-graph -r @ -T description | save -f $tmp_file

      print $tmp_file
    ''
  );

  policyFile =
    let
      toolName = "run_shell_command";
      decision = "allow";
      priority = 100;
    in
    (pkgs.formats.toml { }).generate "nix.toml" {
      rule = [
        {
          inherit toolName decision priority;
          commandPrefix = allowedCommands ++ [ writeCommitMsg ];
        }
      ]
      ++ (lib.attrsets.mapAttrsToList (command: subcommands: {
        inherit toolName decision priority;
        commandRegex = "${command} (${builtins.concatStringsSep "|" subcommands})";
      }) allowedSubcommands);
    };
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
        context.fileFiltering.enableRecursiveFileSearch = true;
        general.preferredEditor = "vim";
        general.previewFeatures = true;
        ide.enabled = true;
        ide.hasSeenNudge = true;
        security.auth.selectedType = "oauth-personal";
        security.enablePermanentToolApproval = true;
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

  # Gemini CLI ignores symlinks. As a workaround, copy the file instead.
  home.activation.copyGeminiPolicy = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p $HOME/.gemini/policies
    run cp -f "${policyFile}" "$HOME/.gemini/policies/nix.toml"
    run chmod 644 "$HOME/.gemini/policies/nix.toml"
  '';

  programs.gemini-cli.commands.commit = {
    description = "Generates a Jujutsu commit based on diff and an optional user input.";
    prompt = ''
      # Task: Generate a Jujutsu commit based on diff and an optional user input.

      ## Context

      !{TMP_FILE=$(${writeCommitMsg}) && echo "Current commit message was extracted to a temporary file: $TMP_FILE"}

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
      2. Run the following command to apply the new message and cleanup: `cat !{echo $TMP_FILE} | jj describe --stdin && rm !{echo $TMP_FILE}`
      3. Run the following command to create a new commit: `jj new`

      ## Optional context provided by the user

    '';
  };
}
