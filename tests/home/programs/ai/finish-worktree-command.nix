# Tests for finish-worktree-command module
{ self, lib }:
let
  config = self.nixosConfigurations.nyancat.config.home-manager.users.dan;

  finishWorktreeCommand = config.home.file.".claude/skills/finish-worktree/SKILL.md".text or "";

  expectedClaude = builtins.readFile (
    self + "/tests/home/programs/ai/finish-worktree.claude-code.md"
  );
in
{
  testFinishWorktreeCommandMatchesGolden = {
    expr = finishWorktreeCommand;
    expected = expectedClaude;
  };
}
