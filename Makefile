default: setup

setup:
	@if test -f /etc/NIXOS; then \
		echo "Running on NixOS, no setup needed."; \
	else \
		sudo puppet apply scripts \
	fi

.PHONY: setup