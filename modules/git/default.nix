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
    userName = "Bohdan Tkachenko";
    userEmail = "bohdan@tkachenko.dev";

    signing = {
      key = null;
      signByDefault = true;
    };

    extraConfig = {
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
    };
  };
}
