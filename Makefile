default: setup

setup:
	@if test -f /etc/NIXOS; then \
		echo "Running on NixOS, no setup needed."; \
		exit 0; \
	fi; \
	\
	sudo puppet apply scripts;	

.PHONY: setup