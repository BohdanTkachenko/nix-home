{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./common.nix
    ./hardware
    ./cli
    ./gui
    ./services/screenshot-path-clipboard.nix
    ./services/winapps.nix
    ./services/yubikey-touch-notifier.nix
  ];

  config = {
    home.username = "dan";
    home.homeDirectory = "/var/home/dan";
    sops.age.sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];

    # Derive a native age identity from the ed25519 SSH key so the `sops`
    # CLI can decrypt without any env-var plumbing. sops-nix already uses
    # the SSH key for activation-time decryption, but the CLI only auto-
    # probes ~/.ssh/id_rsa, so we materialise ~/.config/sops/age/keys.txt
    # on every activation (the file is fully Nix-managed — do not edit).
    home.activation.generateSopsAgeKey = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      sshKey="${config.home.homeDirectory}/.ssh/id_ed25519"
      ageKeyFile="${config.home.homeDirectory}/.config/sops/age/keys.txt"
      if [ -f "$sshKey" ] && [[ ! -v DRY_RUN ]]; then
        mkdir -p "$(dirname "$ageKeyFile")"
        ${pkgs.ssh-to-age}/bin/ssh-to-age -private-key -i "$sshKey" > "$ageKeyFile"
        chmod 600 "$ageKeyFile"
      fi
    '';
  };
}
