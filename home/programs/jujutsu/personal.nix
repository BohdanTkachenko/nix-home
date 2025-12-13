{ ... }:
{
  imports = [
    ./common.nix
  ];

  programs.jujutsu.settings.user.email = "bohdan@tkachenko.dev";

  programs.jujutsu.settings.aliases.fetch = [
    "git"
    "fetch"
  ];
  programs.fish.shellAbbrs.jjf = "jj fetch";

  programs.jujutsu.settings.aliases.pull = [
    "util"
    "exec"
    "--"
    "sh"
    "-c"
    "jj git fetch && jj rebase -d main@origin"
  ];
  programs.fish.shellAbbrs.jjy = "jj pull";

  programs.jujutsu.settings.aliases.push = [
    "git"
    "push"
  ];
  programs.fish.shellAbbrs.jjp = "jj push";

  programs.jujutsu.settings.aliases.main = [
    "bookmark"
    "set"
    "main"
    "-r"
    "@"
  ];
  programs.fish.shellAbbrs.jjm = "jj main";

  programs.jujutsu.settings.aliases.c = [
    "util"
    "exec"
    "--"
    "sh"
    "-c"
    "jj desc && jj bookmark set main -r @ && jj new"
  ];
  programs.fish.shellAbbrs.jjc = "jj c";
}
