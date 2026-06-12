# Security configuration (sudo, TPM, polkit, gnupg, 1password)
{ config, lib, ... }:

{
  security.polkit.enable = true;

  # YubiKey U2F authentication (touch to sudo, with password fallback)
  security.pam.u2f = lib.mkIf config.my.gui.enable {
    enable = true;
    control = "sufficient";
    settings.cue = true;
  };

  programs.yubikey-touch-detector = lib.mkIf config.my.gui.enable {
    enable = true;
    libnotify = false;
  };

  systemd.user.services.yubikey-touch-detector.serviceConfig.Environment = lib.mkIf config.my.gui.enable [
    "YUBIKEY_TOUCH_DETECTOR_LIBNOTIFY=false"
  ];

  security.sudo = {
    wheelNeedsPassword = true;
    extraConfig = ''
      Defaults timestamp_timeout=60
      %wheel ALL=(root) NOPASSWD: /run/current-system/sw/bin/nixos-rebuild switch*
      %wheel ALL=(root) NOPASSWD: /run/current-system/sw/bin/nixos-rebuild boot*
      %wheel ALL=(root) NOPASSWD: /run/current-system/sw/bin/nix-collect-garbage *
      %wheel ALL=(root) NOPASSWD: /run/current-system/sw/bin/ddcutil
    '';
  };

  security.tpm2 = lib.mkIf config.my.secureBoot.enable {
    enable = true;
    pkcs11.enable = true;
    tctiEnvironment.enable = true;
  };

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # 1Password (CLI + GUI) is a desktop concern — follows my.gui.enable.
  programs._1password.enable = config.my.gui.enable;
  programs._1password-gui = lib.mkIf config.my.gui.enable {
    enable = true;
    polkitPolicyOwners = [ "dan" ];
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };
}
