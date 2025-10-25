{ ... }:
{
  programs.git = {
    enable = true;
    userName = "Bohdan Tkachenko";

    extraConfig = {
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
