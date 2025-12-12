{ pkgs, ... }:
let
  gitKeyFinder = pkgs.writeShellScript "git-key-finder" ''
    /usr/bin/ssh-add -L | \
      ${pkgs.gnugrep}/bin/grep -v 'cert' | \
      ${pkgs.coreutils}/bin/head -n 1 | \
      ${pkgs.gawk}/bin/awk '{printf "key::%s %s", $1, $2}'
  '';
in
{
  programs.git = {
    enable = true;

    signing = {
      key = null;
      signByDefault = true;
    };

    settings = {
      user = {
        name = "Bohdan Tkachenko";
        email = "bohdan@tkachenko.dev";
      };
      
      gpg = {
        format = "ssh";
      };

      "gpg \"ssh\"" = {
        defaultKeyCommand = "${gitKeyFinder}";
        program = "/usr/bin/ssh-keygen";
      };

      core = {
        editor = "micro";
      };

      init = {
        defaultBranch = "main";
      };

      push = {
        autoSetupRemote = true;
      };

      pull = {
        rebase = true;
      };

      url = {
        "git@github.com:" = {
          pushInsteadOf = "https://github.com/";
        };
      };
    };
  };
}
