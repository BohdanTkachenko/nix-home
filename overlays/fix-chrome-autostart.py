#! /usr/bin/env python
import argparse
import configparser
import sys
from pathlib import Path

def main():
    parser = argparse.ArgumentParser(description="Fixes Exec lines in Chrome autostart files.")
    parser.add_argument("search_for", help="The exact executable path to search for.")
    parser.add_argument("replace_with", help="The command to replace it with.")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print the changes that would be made without modifying any files.",
    )
    args = parser.parse_args()

    autostart_path = Path.home() / ".config/autostart"
    if not autostart_path.is_dir():
        print(f"INFO: Autostart directory not found: {autostart_path}", file=sys.stderr)
        return

    for desktop_file in list(autostart_path.glob("*.desktop")):
        try:
            if desktop_file.is_symlink():
                if str(desktop_file.readlink()).startswith("/nix/store/"):
                    print(f"INFO: Skipping Nix-managed file: {desktop_file.name}", file=sys.stderr)
                    continue

            config = configparser.ConfigParser(interpolation=None)
            config.optionxform = str
            config.read(desktop_file)

            if not config.has_section("Desktop Entry"):
                continue

            entry = config["Desktop Entry"]
            exec_line = entry.get("Exec", "")
            command_parts = exec_line.split(' ', 1)
            command = command_parts[0]

            if command == args.search_for:
                if args.dry_run:
                    print(f"DRY RUN: {desktop_file.name}: Would change Exec line to use command from PATH.")
                else:
                    new_exec = exec_line.replace(command, args.replace_with, 1)
                    entry["Exec"] = new_exec
                    with open(desktop_file, 'w') as f:
                        config.write(f, space_around_delimiters=False)
                    print(f"MODIFIED: {desktop_file.name}: Updated Exec line to use command from PATH.")
            else:
                print(f"INFO: Skipping {desktop_file.name}: No hardcoded path found.", file=sys.stderr)

        except configparser.Error as e:
            print(f"ERROR: Could not parse {desktop_file.name}: {e}", file=sys.stderr)
            continue

if __name__ == "__main__":
    main()
