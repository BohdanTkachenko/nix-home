{ config, lib, ... }:
{
  # crates.io publish token. Sourced from sops (so it never lands in the
  # world-readable Nix store) and exported into the interactive shell as
  # CARGO_REGISTRY_TOKEN, which `cargo publish` reads. Gated to graphical
  # desktops: the headless workbench box is deliberately not a recipient of
  # this secret (see .sops.yaml) and never publishes crates, so declaring the
  # sops.secret there would fail to decrypt at activation.
  config = lib.mkIf (config.my.secrets.sops.enable && config.my.gui.enable) {
    sops.secrets.cargo-registry-token = {
      sopsFile = ./secrets/cargo.yaml;
      key = "registry_token";
    };

    programs.fish.interactiveShellInit = ''
      if test -r "$HOME/.config/sops-nix/secrets/cargo-registry-token"
        set -gx CARGO_REGISTRY_TOKEN (cat "$HOME/.config/sops-nix/secrets/cargo-registry-token")
      end
    '';
  };
}
