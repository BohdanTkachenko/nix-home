{ ... }:
{
  programs.ssh = {
    controlMaster = "auto";
    controlPath = "~/.ssh/ctrl-%C";
    controlPersist = "yes";

    matchBlocks."*.corp.google.com" = {
      forwardAgent = true;
    };

    matchBlocks."ws" = {
      hostname = "dan.nyc.corp.google.com";
    };
  };

  xdg.desktopEntries.ssh-askpass = {
    name = "ssh-askpass";
    type = "Application";
    exec = "/usr/bin/ssh-askpass";
    terminal = false;
  };
}
