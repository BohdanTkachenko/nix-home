{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:
let
  cfg = config.my;
in
{
  home.packages = [ pkgs.jjui ];

  programs.jujutsu = {
    enable = true;
    package = pkgs-unstable.jujutsu;
    settings = {
      ui.diff-formatter = ":git";
      # NixOS sets PAGER=less globally; without explicit flags jj inherits
      # bare `less` and loses ANSI rendering (codes print literally). Pin the
      # default -FRX flags that jj would have applied if PAGER were unset.
      ui.pager = [
        (lib.getExe pkgs.less)
        "-FRX"
      ];

      user.name = cfg.identity.name;
      user.email = cfg.identity.email;

      signing.behavior = "own";
      signing.backend = "ssh";
      signing.key = "~/.ssh/id_ed25519";

      aliases = {
        lm = [
          "log"
          "-r"
          "main::@"
        ];

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

        parents = [
          "log"
          "-r"
          "@ | parents(@)"
        ];
      }
      // (
        if cfg.google.enable then
          {
            mv = [
              "piper"
              "rename"
            ];
          }
        else
          { }
      );
    };
  };

  programs.fish.shellAbbrs = lib.mkMerge [
    {
      jjd = "jj diff";
      jjs = "jj status";
      jjx = "jj log";
      jjl = "jj lm";
      jje = "jj edit";
      jjep = "jj edit @-";
      jjen = "jj edit @+";
      jjq = "jj squash";
      jjt = "jj split";
      jja = "jj abandon";
      jjj = "jj desc";
      jjn = "jj new";
      jjc = "jj commit";
      jjm = "jj main";
      jjp = "jj push";
      jju = "jj pull";
    }
  ];
}
