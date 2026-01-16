{ isWork, pkgs, ... }:
{
  programs.git = {
    enable = true;

    signing = {
      key = "~/.ssh/id_ed25519";
      signByDefault = true;
    };

    settings = {
      user = {
        name = "Bohdan Tkachenko";
        user.email = if isWork then "bohdant@google.com" else "bohdan@tkachenko.dev";
      };

      gpg = {
        format = "ssh";
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
