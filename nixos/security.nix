# Security configuration (sudo, TPM, polkit, gnupg, 1password)
{ ... }:

{
  security.polkit.enable = true;

  # YubiKey U2F authentication (touch to sudo, with password fallback)
  security.pam.u2f = {
    enable = true;
    control = "sufficient";
    settings.cue = true;
  };

  programs.yubikey-touch-detector = {
    enable = true;
    libnotify = false;
  };

  systemd.user.services.yubikey-touch-detector.serviceConfig.Environment = [
    "YUBIKEY_TOUCH_DETECTOR_LIBNOTIFY=false"
  ];

  security.sudo = {
    wheelNeedsPassword = true;
    extraConfig = ''
      Defaults timestamp_timeout=60
      %wheel ALL=(root) NOPASSWD: /run/current-system/sw/bin/nixos-rebuild switch*
    '';
  };

  security.tpm2 = {
    enable = true;
    pkcs11.enable = true;
    tctiEnvironment.enable = true;
  };

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  programs._1password.enable = true;
  programs._1password-gui = {
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
