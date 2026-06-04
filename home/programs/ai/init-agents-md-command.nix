# Claude Code "init-agents-md" skill.
# Unifies a project's agent-instruction files under AGENTS.md as the single
# source of truth, with CLAUDE.md as a symlink to it. User-invoked only
# (disable-model-invocation), so no allowed-tools list is needed.
{
  config,
  lib,
  ...
}:

let
  description = "Create AGENTS.md as the single source of truth for agent instructions, with CLAUDE.md as a symlink to it. If either already exists (including as a symlink), unify their content into AGENTS.md first. Use when the user wants to consolidate agent/assistant instruction files.";

  markdown = builtins.readFile ./init-agents-md-command.md;

  frontmatter = ''
    ---
    name: init-agents-md
    description: ${description}
    disable-model-invocation: true
    ---
  '';
in
{
  config = {
    home.file.".claude/skills/init-agents-md/SKILL.md" =
      lib.mkIf (config.my ? claude-code && config.my.claude-code.enable) {
        text = frontmatter + markdown;
      };
  };
}
