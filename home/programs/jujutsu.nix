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

      revsets."bookmark-advance-to" = "@-";

      revset-aliases = {
        # origin_trunk matches the primary branch of your personal remote (origin).
        # Rationale: Provides a robust reference to the fork mainline (main or master) without hardcoding branch names.
        "origin_trunk()" = "remote_bookmarks(exact:master, origin) | remote_bookmarks(exact:main, origin)";

        # upstream_trunk matches the official upstream main branches and release branches.
        # Rationale: We intentionally exclude personal forks (origin) and local branches to
        # prevent synchronization lag (e.g. out-of-date master@origin) from polluting branch logs
        # with intermediate upstream commits that haven't been synced to the fork yet.
        "upstream_trunk()" =
          "bookmarks(exact:master) | bookmarks(exact:main) | remote_bookmarks(exact:master, upstream) | remote_bookmarks(exact:main, upstream) | remote_bookmarks(glob:release-*, upstream)";

        # branch_root resolves to the first commit of the current feature branch (the fork point).
        # Mechanics: It takes the set difference between the current working copy (@) and the
        # upstream trunk history, then finds the roots() of that range.
        # Rationale: Enables dynamic branch-wide operations like `jj rebase -s branch_root() -d <dest>`
        # without ever needing to hardcode branch names.
        "branch_root()" = "roots(upstream_trunk()..@)";

        # wc_parents resolves to the current working copy commit and its immediate parents.
        "wc_parents()" = "@ | parents(@)";
      };

      aliases = {
        # lm (Log Main): Shows a clean, linear history of your work leading to @ starting from the repository's trunk.
        lm = [
          "log"
          "-r"
          "trunk()::@"
        ];

        # log-branch: Displays all commits on your current feature branch (from upstream_trunk() to @).
        log-branch = [
          "log"
          "-r"
          "upstream_trunk()..@"
        ];

        # backend: Detects the active repository backend: "git" (via git root), "piper" (Google Monorepo), or default "native".
        backend = [
          "util"
          "exec"
          "--"
          "sh"
          "-c"
          "if jj git root > /dev/null 2>&1; then echo 'git'; elif jj piper repo info > /dev/null 2>&1; then echo 'piper'; else echo 'native'; fi"
        ];

        # pull: Fetches remote updates from the git upstream and rebases work onto origin's trunk (or syncs in a Piper repository).
        pull = [
          "util"
          "exec"
          "--"
          "sh"
          "-c"
          "case $(jj backend) in git) jj git fetch && jj rebase -d 'origin_trunk()' ;; piper) jj sync ;; *) echo 'Unsupported backend'; ;; esac"
        ];

        # push: Commits any active changes by opening a new revision if the working copy is not empty, advances the closest bookmark to @-, and pushes.
        push = [
          "util"
          "exec"
          "--"
          "sh"
          "-c"
          "case $(jj backend) in git) if [ \"$(jj --no-pager log -r @ --no-graph -T 'empty')\" = \"false\" ]; then jj new; fi && jj bookmark advance && jj git push ;; piper) jj upload ;; *) echo 'Unsupported backend'; ;; esac"
        ];
      };
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
      jjp = "jj push";
      jju = "jj pull";
    }
  ];
}
