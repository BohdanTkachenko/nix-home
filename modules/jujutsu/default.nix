{ ... }:
{
  programs.jujutsu = {
    enable = true;
    settings = {
      user = {
        email = "bohdan@tkachenko.dev";
        name = "Bohdan Tkachenko";
      };

      aliases = {
        s = [ "status" ];
        x = [
          "log"
          "-r"
          "(main..@):: | (main..@)-"
        ];
        f = [
          "git"
          "fetch"
        ];
        y = [
          "util"
          "exec"
          "--"
          "sh"
          "-c"
          "jj git fetch && jj rebase -d main@origin"
        ];
        p = [
          "git"
          "push"
        ];
        main = [
          "bookmark"
          "set"
          "main"
          "-r"
          "@"
        ];
      };
    };
  };
}
