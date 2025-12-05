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
        d = [ "diff" ];
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
        c = [
          "util"
          "exec"
          "--"
          "sh"
          "-c"
          "jj desc && jj bookmark set main -r @ && jj new"
        ];
      };
    };
  };
}
