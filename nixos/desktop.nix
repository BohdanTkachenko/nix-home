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

  services.displayManager.autoLogin.user = "dan";
  systemd.services.display-manager.serviceConfig.KeyringMode = lib.mkForce "inherit";
  security.pam.services.sddm-autologin.text = pkgs.lib.mkBefore ''
    auth optional ${pkgs.systemd}/lib/security/pam_systemd_loadkey.so
    auth include sddm
  '';

  programs.xwayland.enable = true;

  environment.gnome.excludePackages = (with pkgs; [
    gnome-tour
  ]);

  environment.systemPackages = with pkgs; [
    google-chrome
    protontricks
  ];

  home-manager.users.dan.xdg.autostart.entries = [
    "${pkgs.google-chrome}/share/applications/google-chrome.desktop"
  ];
}
