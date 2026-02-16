# Tests for jj-commit-command module
{ self, lib }:
let
  config = self.nixosConfigurations.nyancat.config.home-manager.users.dan;

  claudeCommitCommand = config.programs.claude-code.commands.commit or "";
  geminiCommitCommand = config.programs.gemini-cli.commands.commit.prompt or "";
  geminiPolicyFile = builtins.readFile config._geminiPolicyFile;

  # Normalize nix store paths to a placeholder for comparison
  normalizePaths = str:
    builtins.replaceStrings
      [ (builtins.head (builtins.match ".*(/nix/store/[a-z0-9]+-jj-commit-msg/bin/jj-commit-msg).*" str)) ]
      [ "~~JJ_COMMIT_MSG~~" ]
      str;

  # Read golden files from flake source
  expectedClaude = builtins.readFile (self + "/tests/home/programs/ai/jj-commit-command.claude-code.md");
  expectedGemini = builtins.readFile (self + "/tests/home/programs/ai/jj-commit-command.gemini-cli.md");
  expectedGeminiPolicy = builtins.readFile (self + "/tests/home/programs/ai/gemini-cli-policy.toml");
in
{
  testClaudeCodeCommitMatchesGolden = {
    expr = normalizePaths claudeCommitCommand;
    expected = expectedClaude;
  };

  testGeminiCliCommitMatchesGolden = {
    expr = normalizePaths geminiCommitCommand;
    expected = expectedGemini;
  };

  testGeminiCliPolicyMatchesGolden = {
    expr = normalizePaths geminiPolicyFile;
    expected = expectedGeminiPolicy;
  };
}
