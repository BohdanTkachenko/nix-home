---
allowed-tools:
- Bash(just rebuild:*)
description: Rebuild the NixOS/home-manager configuration after making changes to Nix files.
---

After making changes to Nix configuration files, proactively run `just rebuild` to apply them.

- Always rebuild after editing Nix files — don't wait to be asked
- Can be run from any subdirectory of the repo
- Pass through any additional arguments the user provides (e.g., `--show-trace`)
- If the build fails, show the relevant error output and fix the issue
