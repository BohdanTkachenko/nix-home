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

submodules:
	@echo "Updating submodules..."
	@git submodule update --init

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

install: submodules $(HOME)/.config/sops/age/keys.txt
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

$(HOME)/.config/sops/age/keys.txt:
	@echo "Decrypting key..."
	@mkdir -p "$(HOME)/.config/sops/age"
	@nix-shell -p age --run "age --decrypt --output='$(HOME)/.config/sops/age/keys.txt' key.txt.age"

code:
	@echo "Opening project in VSCode..."
	@code "$(mkfile_dir)"

.PHONY: default setup setup-hm install install-nixos install-hm update code