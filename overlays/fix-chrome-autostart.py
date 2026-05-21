#!/usr/bin/env python3
import sys
import os
from pathlib import Path

def main():
    if len(sys.argv) < 3:
        print("Usage: fix-chrome-autostart.py <search_pattern> <replace_pattern> [--dry-run]", file=sys.stderr)
        sys.exit(1)

    search_pat = sys.argv[1]
    replace_pat = sys.argv[2]
    dry_run = "--dry-run" in sys.argv

    autostart_dir = Path(os.environ.get("HOME", "/")) / ".config" / "autostart"
    if not autostart_dir.is_dir():
        print(f"Autostart directory not found: {autostart_dir}", file=sys.stderr)
        sys.exit(0)

    for desktop_file in autostart_dir.glob("*.desktop"):
        try:
            content = desktop_file.read_text()
            lines = content.splitlines()
            modified = False
            for i, line in enumerate(lines):
                if line.startswith("Exec="):
                    exec_part = line[5:]
                    if search_pat in exec_part:
                        new_exec = exec_part.replace(search_pat, replace_pat)
                        lines[i] = f"Exec={new_exec}"
                        modified = True
            
            if modified:
                if dry_run:
                    print(f"DRY RUN: Would modify {desktop_file.name}")
                else:
                    desktop_file.write_text("\n".join(lines) + "\n")
                    print(f"Modified {desktop_file.name}")
        except Exception as e:
            print(f"Error processing {desktop_file.name}: {e}", file=sys.stderr)

if __name__ == "__main__":
    main()
