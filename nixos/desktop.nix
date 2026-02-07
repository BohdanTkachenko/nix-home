# Desktop environment configuration (GNOME, audio, display)
{ lib, pkgs, ... }:

{
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  programs.xwayland.enable = true;

  environment.gnome.excludePackages = (
    with pkgs;
    [
      gnome-tour
    ]
  );

  environment.systemPackages = with pkgs; [
    google-chrome
    protontricks
  ];
}
