{ ... }:
{
  programs.jujutsu = {
    enable = true;
    settings = {
      user = {
        email = "bohdan@tkachenko.dev";
        name = "Bohdan Tkachenko";
      };

      signing = {
        behavior = "own";
        backend = "ssh";
        key = "~/.ssh/id_ed25519";
      };

      aliases = {
        s = [ "status" ];
        x = [
          "log"
          "-r"
          "(main..@):: | (main..@)-"
        ];
        l = [
          "log"
          "-r"
          "::main"
          "-n"
          "10"
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
