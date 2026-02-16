# Commit commands for claude-code and gemini-cli.
# Both generate Jujutsu commits based on diff and optional user input.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Script for managing jj commit messages via temp files.
  # Subcommands:
  #   write - Extract current commit message to temp file, prints path
  #   apply <file> - Apply commit message from file and delete it
  jjCommitMsg = lib.getExe (
    pkgs.writers.writeNuBin "jj-commit-msg" (builtins.readFile ./jj-commit-msg.nu)
  );

  description = "Generates a Jujutsu commit based on diff and an optional user input.";

  # Unified shell syntax: %!`command`!%
  # Transforms to:
  #   Claude: !`command`
  #   Gemini: !{command}
  toClaudeSyntax = str:
    builtins.replaceStrings [ "%!\`" "\`!%" ] [ "!\`" "\`" ] str;

  toGeminiSyntax = str:
    builtins.replaceStrings [ "%!\`" "\`!%" ] [ "!{" "}" ] str;

  # Read markdown template and substitute jjCommitMsg path
  markdown = builtins.replaceStrings
    [ "{{JJ_COMMIT_MSG}}" ]
    [ jjCommitMsg ]
    (builtins.readFile ./jj-commit-command.md);

  claudeMarkdown = toClaudeSyntax markdown;
  geminiMarkdown = toGeminiSyntax markdown;

  claudeFrontmatter =
    let
      allowedTools = [
        "Bash(jj status:*)"
        "Bash(jj log:*)"
        "Bash(jj diff:*)"
        "Bash(jj show:*)"
        "Bash(${jjCommitMsg} write)"
        "Bash(${jjCommitMsg} apply *)"
        "Read(*.jj/tmp/jj-commit-message.*)"
        "Write(*.jj/tmp/jj-commit-message.*)"
      ];
      toolsList = lib.concatMapStringsSep "\n" (t: "- ${t}") allowedTools;
    in
    ''
      ---
      allowed-tools:
      ${toolsList}
      description: ${description}
      ---
    '';
in
{
  options._jjCommitMsg = lib.mkOption {
    type = lib.types.str;
    internal = true;
    description = "Path to jj-commit-msg script for policy files";
  };

  config = {
    _jjCommitMsg = jjCommitMsg;

    programs.claude-code.commands.commit = claudeFrontmatter + claudeMarkdown;

    programs.gemini-cli.commands.commit = {
      inherit description;
      prompt = geminiMarkdown;
    };
  };
}
