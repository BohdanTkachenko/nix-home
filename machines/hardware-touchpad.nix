# Touchpad configuration
{ ... }:
{
  services.libinput = {
    enable = true;
    touchpad = {
      accelSpeed = "0.3";
      clickMethod = "clickfinger";
      disableWhileTyping = true;
      scrollMethod = "twofinger";
      naturalScrolling = true;
      tapping = false;
    };
  };
}