# Tests for jj-commit-command module
{ self, lib }:
let
  config = self.nixosConfigurations.nyancat.config.home-manager.users.dan;

  claudeCommitCommand = config.home.file.".claude/skills/commit/SKILL.md".text or "";
  geminiCommitCommand = config.programs.gemini-cli.commands.commit.prompt or "";
  geminiPolicyFile = builtins.readFile config._geminiPolicyFile;

  # Read golden files from flake source
  expectedClaude = builtins.readFile (
    self + "/tests/home/programs/ai/jj-commit-command.claude-code.md"
  );
  expectedGemini = builtins.readFile (
    self + "/tests/home/programs/ai/jj-commit-command.gemini-cli.md"
  );
  expectedGeminiPolicy = builtins.readFile (self + "/tests/home/programs/ai/gemini-cli-policy.toml");
in
{
  testClaudeCodeCommitMatchesGolden = {
    expr = claudeCommitCommand;
    expected = expectedClaude;
  };

  testGeminiCliCommitMatchesGolden = {
    expr = geminiCommitCommand;
    expected = expectedGemini;
  };

  testGeminiCliPolicyMatchesGolden = {
    expr = geminiPolicyFile;
    expected = expectedGeminiPolicy;
  };
}
