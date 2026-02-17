set dotenv-load

root_dir := justfile_directory()

verbose_flag := if env("VERBOSE", "") != "" { "-v" } else { "" }

rebuild-nixos:
    @echo "Running on NixOS, using nixos-rebuild..."
    sudo nixos-rebuild switch --flake "path:{{ root_dir }}" {{ verbose_flag }}

rebuild-hm:
    #!/usr/bin/env bash
    echo "Executing home-manager switch..."
    HM_CMD_SWITCH="home-manager switch"
    SOURCE_NIX_DAEMON=""
    if ! command -v home-manager >/dev/null 2>&1; then
        HM_CMD_SWITCH="nix run home-manager -- switch -b backup"
        SOURCE_NIX_DAEMON="if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh; fi;"
    fi
    eval "$SOURCE_NIX_DAEMON" $HM_CMD_SWITCH \
        --flake "path:{{ root_dir }}" \
        {{ verbose_flag }}

rebuild:
    #!/usr/bin/env bash
    if test -f /etc/NIXOS; then
        just install-nixos
    else
        just install-hm
    fi

update:
    @echo "Updating flake inputs..."
    nix flake update --flake "path:{{ root_dir }}"
    @echo "Applying updates..."
    just rebuild

sops_files := "nixos/secrets/wireguard.yaml home/programs/ssh/private-ssh-config"

test:
    nix flake check --flake "path:{{ root_dir }}" {{ verbose_flag }}

rekey:
    #!/usr/bin/env bash
    export SOPS_AGE_KEY=$(nix-shell -p ssh-to-age --run "ssh-to-age -private-key -i $HOME/.ssh/id_ed25519")
    for f in {{ sops_files }}; do
        sops updatekeys -y "{{ root_dir }}/$f"
    done
