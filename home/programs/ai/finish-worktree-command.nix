# Claude Code "finish-worktree" skill.
# Folds a Claude Code git worktree's work into the main repo's `main` bookmark
# (via jj), then resets the worktree to its birth commit so it exits cleanly.
# Relies on the jj describe-to-file/from-file aliases from jj-commit-command.nix.
{
  config,
  lib,
  ...
}:

let
  description = "Integrate a Claude Code worktree's work into main (via jj) and reset it for a clean exit.";

  markdown = builtins.readFile ./finish-worktree-command.md;

  frontmatter =
    let
      allowedTools = [
        "Bash(jj root:*)"
        "Bash(jj diff:*)"
        "Bash(jj status:*)"
        "Bash(jj log:*)"
        "Bash(jj show:*)"
        "Bash(jj new:*)"
        "Bash(jj bookmark:*)"
        "Bash(jj describe-to-file *)"
        "Bash(jj describe-from-file *)"
        "Bash(git rev-parse:*)"
        "Bash(git rev-list:*)"
        "Bash(git status:*)"
        "Bash(git add:*)"
        "Bash(git diff:*)"
        "Bash(git log:*)"
        "Bash(git apply:*)"
        "Bash(git reset:*)"
        "Read(//tmp/jj-commit-msg/*)"
        "Write(//tmp/jj-commit-msg/*)"
      ];
      toolsList = lib.concatMapStringsSep "\n" (t: "- ${t}") allowedTools;
    in
    ''
      ---
      name: finish-worktree
      allowed-tools:
      ${toolsList}
      description: ${description}
      context: fork
      agent: general-purpose
      ---
    '';
in
{
  config = {
    home.file.".claude/skills/finish-worktree/SKILL.md" =
      lib.mkIf (config.my ? claude-code && config.my.claude-code.enable) {
        text = frontmatter + markdown;
      };
  };
}
