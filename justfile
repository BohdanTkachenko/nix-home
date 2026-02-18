set dotenv-load

sops_files := "nixos/secrets/wireguard.yaml home/programs/ssh/private-ssh-config home/services/secrets/winapps.yaml"

root_dir := justfile_directory()
flake_arg := '--flake "path:' + root_dir + '"'

is_nixos := `if [ -f /etc/NIXOS ]; then echo true; else echo false; fi`
switch_cmd := if is_nixos == "true" { "sudo nixos-rebuild switch" } else { "home-manager switch" }

default:
  @just --choose

rebuild *args:
    {{ switch_cmd }} {{ flake_arg }} {{ args }}

update flake_update_args="" *rebuild_args:
    nix flake update {{ flake_arg }} {{ flake_update_args }}
    just rebuild {{ rebuild_args }}

test *args:
    nix flake check {{ flake_arg }} {{ args }}

show-age-pubkey:
    @nix-shell -p ssh-to-age --run "ssh-to-age -i $HOME/.ssh/id_ed25519.pub"

rekey +files=sops_files:
    #!/usr/bin/env bash
    export SOPS_AGE_KEY=$(nix-shell -p ssh-to-age --run "ssh-to-age -private-key -i $HOME/.ssh/id_ed25519")
    for f in {{ files }}; do
        sops updatekeys -y "{{ root_dir }}/$f"
    done
