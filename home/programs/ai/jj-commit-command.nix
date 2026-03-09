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
  toClaudeSyntax =
    str:
    builtins.replaceStrings [ "{{TMP_DIR}}" "%!\`" "\`!%" ] [ "/tmp/jj-commit-msg" "!\`" "\`" ] str;

  toGeminiSyntax =
    str:
    builtins.replaceStrings
      [ "{{TMP_DIR}}" "%!\`" "\`!%" ]
      [ "${config.home.homeDirectory}/.gemini/tmp/jj-commit-msg" "!{" "}" ]
      str;

  # Read markdown template and substitute jjCommitMsg path
  markdown = builtins.readFile ./jj-commit-command.md;
  claudeMarkdown = toClaudeSyntax markdown;
  geminiMarkdown = toGeminiSyntax markdown;

  claudeFrontmatter =
    let
      allowedTools = [
        "Bash(jj status:*)"
        "Bash(jj log:*)"
        "Bash(jj diff:*)"
        "Bash(jj show:*)"
        "Bash(jj describe-to-file *)"
        "Bash(jj describe-from-file *)"
        "Read(/tmp/jj-commit-msg/*)"
        "Write(/tmp/jj-commit-msg/*)"
      ];
      toolsList = lib.concatMapStringsSep "\n" (t: "- ${t}") allowedTools;
    in
    ''
      ---
      allowed-tools:
      ${toolsList}
      description: ${description}
      context: fork
      agent: general-purpose
      ---
    '';
in
{
  imports = [
    ./jj-describe-to-from-file.nix
  ];

  config = {
    programs.claude-code.commands.commit = claudeFrontmatter + claudeMarkdown;

    programs.gemini-cli.commands.commit = {
      inherit description;
      prompt = geminiMarkdown;
    };
  };
}
