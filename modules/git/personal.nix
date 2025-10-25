{ pkgs, ... }:
{
  programs.git = {
    userEmail = "bohdan@tkachenko.dev";

    signing = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDrWBrKDssaTRUUStKYtEr/c2GQg0PhSXfakpMQSq346";
      format = "ssh";
      signByDefault = true;
      signer = "${pkgs._1password-gui}/bin/op-ssh-sign";
    };
  };
}
