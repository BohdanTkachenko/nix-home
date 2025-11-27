mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
mkfile_dir := $(dir $(mkfile_path))

ifneq (,$(wildcard ./.env))
    include .env
    export
endif

HOME_MANAGER_HOST := $(subst ",,$(HOME_MANAGER_HOST))
HOME_MANAGER_ENV := $(subst ",,$(HOME_MANAGER_ENV))

IMPURE_FLAG :=
ifeq ($(HOME_MANAGER_HOST), personal-pc)
IMPURE_FLAG := --impure
endif

VERBOSE_FLAG :=
ifdef VERBOSE
VERBOSE_FLAG := -v
endif

# Check if home-manager is in the PATH, and set up fallbacks if not
HM_CMD_SWITCH := home-manager switch
SOURCE_NIX_DAEMON :=
ifeq (, $(shell command -v home-manager 2>/dev/null))
	HM_CMD_SWITCH := nix run home-manager -- switch -b backup
	SOURCE_NIX_DAEMON := if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh; fi;
endif

default: install

configure: .env

.env:
	@scripts/configure.sh

bootstrap: configure
	@if [ -n "$$FORCE" ] || ! command -v home-manager &> /dev/null; then \
		$(HOME_MANAGER_SWITCH_VERBOSE_ENV) $(HOME_MANAGER_SWITCH_IMPURE_ENV) ./scripts/bootstrap.sh; \
	else \
		echo "home-manager is already installed. Skipping bootstrap."; \
	fi

submodules:
	@echo "Updating submodules..."
	@git submodule update --init

install: bootstrap submodules
	@echo "Executing home-manager switch..."
	@$(SOURCE_NIX_DAEMON) \
	$(HM_CMD_SWITCH) \
		--flake "path:$(mkfile_dir)#${HOME_MANAGER_HOST}" \
		$(VERBOSE_FLAG) $(IMPURE_FLAG)

update:
	@echo "Updating flake inputs..."
	@nix flake update --flake "path:$(mkfile_dir)"
	@echo "Applying updates..."
	@$(MAKE) install

key-decrypt:
	mkdir "$HOME/.config/sops/age"
	nix-shell -p age --command "age --decrypt --output='$HOME/.config/sops/age/keys.txt' key.txt.age"

clean:
	@echo "Cleaning generated files..."
	@rm -f .env
	@echo "Clean complete."

code:
	@echo "Opening project in VSCode..."
	@code "$(mkfile_dir)"

.PHONY: default configure bootstrap install update clean code