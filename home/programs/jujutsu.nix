{ config, lib, pkgs, ... }:
let
  isPersonal = config.custom.profile == "personal";
  isWork = config.custom.profile == "work";
in
{
  programs.jujutsu = {
    enable = true;
    package = lib.mkIf isWork (pkgs.writeScriptBin "jj" ''#!/bin/sh
exec /usr/bin/jj "$@"
'');
    settings = {
      user.name = "Bohdan Tkachenko";
      user.email =
        if isPersonal then "bohdan@tkachenko.dev" else "bohdant@google.com";

      signing.behavior = "own";
      signing.backend = "ssh";
      signing.key = "~/.ssh/id_ed25519";

      aliases = lib.mkMerge [
        # Personal aliases (git-based workflow)
        (lib.mkIf isPersonal {
          fetch = [
            "git"
            "fetch"
          ];
          pull = [
            "util"
            "exec"
            "--"
            "sh"
            "-c"
            "jj git fetch && jj rebase -d main@origin"
          ];
          push = [
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
        })

        # Work aliases (sync/upload workflow)
        (lib.mkIf isWork {
          y = [ "sync" ];
          p = [ "upload" ];
          c = [
            "util"
            "exec"
            "--"
            "sh"
            "-c"
            "jj desc && jj new"
          ];
        })
      ];
    };
  };

  # Common fish abbreviations
  programs.fish.shellAbbrs = lib.mkMerge [
    {
      jjd = "jj diff";
      jjs = "jj status";
      jje = "jj edit";
      jjq = "jj squash";
      jjj = "jj desc";
      jjx = "jj log";
      jjc = "jj c";
    }

    # Personal-specific abbrs
    (lib.mkIf isPersonal {
      jjf = "jj fetch";
      jjy = "jj pull";
      jjp = "jj push";
      jjm = "jj main";
    })

    # Work-specific abbrs
    (lib.mkIf isWork {
      jjy = "jj y";
      jjp = "jj p";
    })
  ];
}
