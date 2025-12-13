{ ... }:
{
  programs.jujutsu = {
    enable = true;
    settings = {
      user.name = "Bohdan Tkachenko";

      signing.behavior = "own";
      signing.backend = "ssh";
      signing.key = "~/.ssh/id_ed25519";
    };
  };

  programs.fish.shellAbbrs.jjd = "jj diff";
  programs.fish.shellAbbrs.jjs = "jj status";
  programs.fish.shellAbbrs.jje = "jj edit";
  programs.fish.shellAbbrs.jjq = "jj squash";
  programs.fish.shellAbbrs.jjj = "jj desc";
  programs.fish.shellAbbrs.jjx = "jj log";
}
