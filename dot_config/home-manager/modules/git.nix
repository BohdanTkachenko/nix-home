{ pkgs, ... }:

{
  programs.git = {
    enable = true;
    userEmail = "bohdan@tkachenko.dev";
    userName = "Bohdan Tkachenko";

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
    };
  };
}
