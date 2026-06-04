# Claude Code "init-devshell" skill.
# Scaffolds (or upgrades) a project's Nix devShell to the `.nix-profile`
# symlink pattern with a `refresh` script and direnv. User-invoked only
# (disable-model-invocation), so no allowed-tools list is needed.
{
  config,
  lib,
  ...
}:

let
  description = "Set up a Nix devShell with direnv and the .nix-profile symlink pattern for a project. Use when a project has a flake.nix without the refresh/profile setup, or no flake.nix at all.";

  markdown = builtins.readFile ./init-devshell-command.md;

  frontmatter = ''
    ---
    name: init-devshell
    description: ${description}
    disable-model-invocation: true
    ---
  '';
in
{
  config = {
    home.file.".claude/skills/init-devshell/SKILL.md" =
      lib.mkIf (config.my ? claude-code && config.my.claude-code.enable) {
        text = frontmatter + markdown;
      };
  };
}
