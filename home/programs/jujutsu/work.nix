{ ... }:
{
  imports = [
    ./common.nix
  ];

  programs.jujutsu.settings.user.email = "bohdant@google.com";

  programs.jujutsu.settings.aliases.y = [ "sync" ];
  programs.fish.shellAbbrs.jjy = "jj y";

  programs.jujutsu.settings.aliases.p = [ "upload" ];
  programs.fish.shellAbbrs.jjp = "jj p";

  programs.jujutsu.settings.aliases.c = [
    "util"
    "exec"
    "--"
    "sh"
    "-c"
    "jj desc && jj new"
  ];
  programs.fish.shellAbbrs.jjc = "jj c";
}
