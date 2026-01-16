{
  pkgs-unstable,
  ...
}:

{
  programs.claude-code = {
    enable = true;
    package = pkgs-unstable.claude-code;

    commands = {
      commit = ''
        ---
        allowed-tools: Bash(jj status:*), Bash(jj log:*), Bash(jj diff:*), Bash(jj desc:*), Bash(jj new:*), Bash(jj show:*)
        description: Describe current jj change
        ---
        ## Context

        ### Current commit description and changes in current revision:

        !`jj show --stat --git --ignore-all-space`

        ### Recent commits: !`jj log --no-graph --limit 5`

        ## Task

        Based on the changes above, create a jj commit description and then create a new commit.
      '';
    };
  };
}
