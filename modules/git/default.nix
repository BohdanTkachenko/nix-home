{ pkgs, ... }:
{
  programs.git = {
    enable = true;
    userName = "Bohdan Tkachenko";
    userEmail = "bohdan@tkachenko.dev";

    signing = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDrWBrKDssaTRUUStKYtEr/c2GQg0PhSXfakpMQSq346";
      format = "ssh";
      signByDefault = true;
      signer = "${pkgs._1password-gui}/bin/op-ssh-sign";
    };

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
