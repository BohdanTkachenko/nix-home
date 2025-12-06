{ ... }:
{
  imports = [
    ./common.nix
  ];

  programs.jujutsu.settings.user.email = "bohdan@tkachenko.dev";

  programs.jujutsu.settings.aliases.f = [
    "git"
    "fetch"
  ];
  programs.fish.shellAbbrs.jjf = "jj f";

  programs.jujutsu.settings.aliases.y = [
    "util"
    "exec"
    "--"
    "sh"
    "-c"
    "jj git fetch && jj rebase -d main@origin"
  ];
  programs.fish.shellAbbrs.jjy = "jj y";

  programs.jujutsu.settings.aliases.p = [
    "git"
    "push"
  ];
  programs.fish.shellAbbrs.jjp = "jj p";

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
