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

  programs.jujutsu.settings.aliases.d = [ "diff" ];
  programs.fish.shellAbbrs.jjd = "jj x";

  programs.jujutsu.settings.aliases.s = [ "status" ];
  programs.fish.shellAbbrs.jjs = "jj s";

  programs.jujutsu.settings.aliases.e = [ "edit" ];
  programs.fish.shellAbbrs.jje = "jj e";

  programs.jujutsu.settings.aliases.q = [ "squash" ];
  programs.fish.shellAbbrs.jjq = "jj q";

  programs.jujutsu.settings.aliases.j = [ "desc" ];
  programs.fish.shellAbbrs.jjj = "jj j";

  programs.jujutsu.settings.aliases.x = [
    "log"
    "-r"
    "(main..@):: | (main..@)-"
  ];
  programs.fish.shellAbbrs.jjx = "jj x";

  programs.jujutsu.settings.aliases.l = [
    "log"
    "-r"
    "::main"
  ];
  programs.fish.shellAbbrs.jjl = "jj l";

}
