mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
mkfile_dir := $(dir $(mkfile_path))

ifneq (,$(wildcard ./.env))
    include .env
    export
endif

VERBOSE_FLAG :=
ifdef VERBOSE
VERBOSE_FLAG := -v
endif

default: install

setup:
	@if test -f /etc/NIXOS; then \
		echo "Running on NixOS, no setup needed."; \
	else \
		$(MAKE) setup-hm; \
	fi

setup-hm:
	sudo puppet apply scripts

install-nixos:
	@echo "Running on NixOS, using nixos-rebuild..."
	sudo nixos-rebuild switch --flake "path:$(mkfile_dir)" $(VERBOSE_FLAG)

install-hm:
	@echo "Executing home-manager switch..."
	@HM_CMD_SWITCH="home-manager switch"; \
	SOURCE_NIX_DAEMON=""; \
	if ! command -v home-manager >/dev/null 2>&1; then \
		HM_CMD_SWITCH="nix run home-manager -- switch -b backup"; \
		SOURCE_NIX_DAEMON="if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh; fi;"; \
	fi; \
	$$SOURCE_NIX_DAEMON $$HM_CMD_SWITCH \
		--flake "path:$(mkfile_dir)" \
		$(VERBOSE_FLAG)

install:
	@if test -f /etc/NIXOS; then \
		$(MAKE) install-nixos; \
	else \
		$(MAKE) install-hm; \
	fi

update:
	@echo "Updating flake inputs..."
	@nix flake update --flake "path:$(mkfile_dir)"
	@echo "Applying updates..."
	@$(MAKE) install

SOPS_FILES := nixos/secrets/wireguard.yaml home/programs/ssh/private-ssh-config

rekey:
	@export SOPS_AGE_KEY=$$(nix-shell -p ssh-to-age --run "ssh-to-age -private-key -i $$HOME/.ssh/id_ed25519") && \
	for f in $(SOPS_FILES); do \
		sops updatekeys -y "$(mkfile_dir)/$$f"; \
	done

code:
	@echo "Opening project in VSCode..."
	@code "$(mkfile_dir)"

.PHONY: default setup setup-hm install install-nixos install-hm update rekey code