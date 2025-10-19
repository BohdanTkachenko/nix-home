#!/usr/bin/env python
import argparse
import configparser
import logging
import sys
from pathlib import Path

class ColoredFormatter(logging.Formatter):
    """A custom logging formatter that adds colors in a TTY."""

    COLORS = {
        "WARNING": "\033[93m",  # Yellow
        "INFO": "\033[92m",     # Green
        "DEBUG": "\033[96m",    # Cyan
        "ERROR": "\033[91m",    # Red
        "RESET": "\033[0m",
    }

    def __init__(self, fmt, use_color=True):
        super().__init__(fmt)
        self.use_color = use_color

    def format(self, record):
        if self.use_color and record.levelname in self.COLORS:
            record.levelname = f"{self.COLORS[record.levelname]}{record.levelname}{self.COLORS['RESET']}"
        return super().format(record)

def main():
    parser = argparse.ArgumentParser(
        description="Fixes the StartupWMClass in Chromium PWA .desktop files to match the Icon value."
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print the changes that would be made without modifying any files.",
    )
    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="Enable verbose (DEBUG level) logging.",
    )
    parser.add_argument(
        "--apps-dir",
        type=Path,
        default=Path.home() / ".local/share/applications/",
        help="The directory to scan for .desktop files. Defaults to ~/.local/share/applications/",
    )
    args = parser.parse_args()

    # Setup logging
    log = logging.getLogger()
    log_level = logging.DEBUG if args.verbose else logging.INFO
    log.setLevel(log_level)

    handler = logging.StreamHandler()
    formatter = ColoredFormatter(
        "%(levelname)s: %(message)s",
        use_color=sys.stdout.isatty()
    )
    handler.setFormatter(formatter)
    log.addHandler(handler)

    app_path = args.apps_dir.expanduser()
    if not app_path.is_dir():
        logging.debug(f"Directory not found: {app_path}")
        return

    logging.debug(f"Scanning directory: {app_path}")
    for desktop_file in app_path.glob("*.desktop"):
        logging.debug(f"Checking file: {desktop_file.name}")
        try:
            config = configparser.ConfigParser(interpolation=None)
            config.optionxform = str  # Preserve key case
            config.read(desktop_file)

            if not config.has_section("Desktop Entry"):
                logging.debug(" -> Skipped: No [Desktop Entry] section.")
                continue

            entry = config["Desktop Entry"]
            if "--app-id=" not in entry.get("Exec", ""):
                logging.debug(" -> Skipped: Not a Chromium PWA (no --app-id= in Exec).")
                continue

            icon = entry.get("Icon")
            wm_class = entry.get("StartupWMClass")

            if not icon or not wm_class:
                logging.debug(" -> Skipped: Missing Icon or StartupWMClass.")
                continue

            if icon != wm_class:
                logging.debug(f" -> Mismatch: Icon='{icon}' vs StartupWMClass='{wm_class}'")
                if args.dry_run:
                    logging.info(
                        f"DRY RUN: {desktop_file.name}: Would change StartupWMClass."
                    )
                else:
                    entry["StartupWMClass"] = icon
                    with open(desktop_file, 'w') as f:
                        config.write(f, space_around_delimiters=False)
                    logging.info(f"MODIFIED: {desktop_file.name}: Updated StartupWMClass.")
            else:
                logging.info(f"OK: {desktop_file.name}: StartupWMClass already correct.")

        except configparser.Error as e:
            logging.error(f" -> Skipped {desktop_file.name}: Could not parse file. Error: {e}")
            continue

if __name__ == "__main__":
    main()
