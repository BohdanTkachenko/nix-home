{
  config,
  lib,
  isWork,
  pkgs,
  ...
}:
{
  programs.jujutsu = {
    enable = true;
    package = lib.mkIf isWork (
      pkgs.writeScriptBin "jj" ''
        #!/bin/sh
        exec /usr/bin/jj "$@"
      ''
    );
    settings = {
      user.name = "Bohdan Tkachenko";
      user.email = if isWork then "bohdant@google.com" else "bohdan@tkachenko.dev";

      signing.behavior = "own";
      signing.backend = "ssh";
      signing.key = "~/.ssh/id_ed25519";

      aliases = {
        backend = [
          "util"
          "exec"
          "--"
          "sh"
          "-c"
          "if jj git root > /dev/null 2>&1; then echo 'git'; elif jj piper repo info > /dev/null 2>&1; then echo 'piper'; else echo 'native'; fi"
        ];

        main = [
          "util"
          "exec"
          "--"
          "sh"
          "-c"
          "case $(jj backend) in git) jj bookmark set -r @- main && jj rebase -d main@origin ;; *) echo 'Unsupported backend'; ;; esac"
        ];

        pull = [
          "util"
          "exec"
          "--"
          "sh"
          "-c"
          "case $(jj backend) in git) jj git fetch && jj rebase -d main@origin ;; piper) jj sync ;; *) echo 'Unsupported backend'; ;; esac"
        ];

        push = [
          "util"
          "exec"
          "--"
          "sh"
          "-c"
          "case $(jj backend) in git) jj git push ;; piper) jj upload ;; *) echo 'Unsupported backend'; ;; esac"
        ];
      };
    };
  };

  programs.fish.shellAbbrs = lib.mkMerge [
    {
      jjd = "jj diff";
      jjs = "jj status";
      jje = "jj edit";
      jjq = "jj squash";
      jjj = "jj desc";
      jjx = "jj log";
      jjc = "jj commit";
      jjp = "jj push";
      jju = "jj pull";
    }
  ];
}
