#!/usr/bin/env python3
"""Tests for the fix-chrome-autostart script."""

import configparser
import os
import subprocess
import sys
import tempfile
from pathlib import Path

# Allow override via environment variable for Nix builds
SCRIPT_PATH = Path(os.environ.get(
    "FIX_CHROME_AUTOSTART_SCRIPT",
    Path(__file__).parent.parent / "overlays" / "fix-chrome-autostart.py"
))


def create_desktop_file(path: Path, exec_line: str, name: str = "Test App") -> None:
    """Create a .desktop file with the given Exec line."""
    config = configparser.ConfigParser(interpolation=None)
    config.optionxform = str
    config["Desktop Entry"] = {
        "Type": "Application",
        "Name": name,
        "Exec": exec_line,
    }
    with open(path, "w") as f:
        config.write(f, space_around_delimiters=False)


def read_exec_line(path: Path) -> str:
    """Read the Exec line from a .desktop file."""
    config = configparser.ConfigParser(interpolation=None)
    config.optionxform = str
    config.read(path)
    return config["Desktop Entry"]["Exec"]


def run_script(*args: str) -> subprocess.CompletedProcess:
    """Run the fix-chrome-autostart script with the given arguments."""
    return subprocess.run(
        [sys.executable, str(SCRIPT_PATH), *args],
        capture_output=True,
        text=True,
    )


def test_replaces_matching_exec():
    """Test that the script replaces Exec lines that match the search pattern."""
    with tempfile.TemporaryDirectory() as tmpdir:
        autostart = Path(tmpdir) / ".config" / "autostart"
        autostart.mkdir(parents=True)

        desktop_file = autostart / "chrome-app.desktop"
        original_exec = "/opt/google/chrome/google-chrome --app-id=abc123"
        create_desktop_file(desktop_file, original_exec)

        # Patch HOME to use our temp directory
        import os
        old_home = os.environ.get("HOME")
        os.environ["HOME"] = tmpdir
        try:
            result = run_script("/opt/google/chrome/google-chrome", "google-chrome-stable")
        finally:
            if old_home:
                os.environ["HOME"] = old_home
            else:
                del os.environ["HOME"]

        assert result.returncode == 0, f"Script failed: {result.stderr}"
        new_exec = read_exec_line(desktop_file)
        assert new_exec == "google-chrome-stable --app-id=abc123", f"Unexpected Exec: {new_exec}"
        print("PASS: test_replaces_matching_exec")


def test_skips_non_matching_exec():
    """Test that the script skips files that don't match the search pattern."""
    with tempfile.TemporaryDirectory() as tmpdir:
        autostart = Path(tmpdir) / ".config" / "autostart"
        autostart.mkdir(parents=True)

        desktop_file = autostart / "other-app.desktop"
        original_exec = "/usr/bin/some-other-app --flag"
        create_desktop_file(desktop_file, original_exec)

        import os
        old_home = os.environ.get("HOME")
        os.environ["HOME"] = tmpdir
        try:
            result = run_script("/opt/google/chrome/google-chrome", "google-chrome-stable")
        finally:
            if old_home:
                os.environ["HOME"] = old_home
            else:
                del os.environ["HOME"]

        new_exec = read_exec_line(desktop_file)
        assert new_exec == original_exec, f"File was modified when it shouldn't be: {new_exec}"
        print("PASS: test_skips_non_matching_exec")


def test_dry_run_does_not_modify():
    """Test that --dry-run doesn't modify any files."""
    with tempfile.TemporaryDirectory() as tmpdir:
        autostart = Path(tmpdir) / ".config" / "autostart"
        autostart.mkdir(parents=True)

        desktop_file = autostart / "chrome-app.desktop"
        original_exec = "/opt/google/chrome/google-chrome --app-id=abc123"
        create_desktop_file(desktop_file, original_exec)

        import os
        old_home = os.environ.get("HOME")
        os.environ["HOME"] = tmpdir
        try:
            result = run_script("/opt/google/chrome/google-chrome", "google-chrome-stable", "--dry-run")
        finally:
            if old_home:
                os.environ["HOME"] = old_home
            else:
                del os.environ["HOME"]

        assert result.returncode == 0, f"Script failed: {result.stderr}"
        assert "DRY RUN" in result.stdout, "Expected DRY RUN message"
        new_exec = read_exec_line(desktop_file)
        assert new_exec == original_exec, f"File was modified during dry run: {new_exec}"
        print("PASS: test_dry_run_does_not_modify")


def test_handles_missing_autostart_dir():
    """Test that the script handles missing autostart directory gracefully."""
    with tempfile.TemporaryDirectory() as tmpdir:
        # Don't create the autostart directory
        import os
        old_home = os.environ.get("HOME")
        os.environ["HOME"] = tmpdir
        try:
            result = run_script("/opt/google/chrome/google-chrome", "google-chrome-stable")
        finally:
            if old_home:
                os.environ["HOME"] = old_home
            else:
                del os.environ["HOME"]

        assert result.returncode == 0, f"Script should succeed with missing dir: {result.stderr}"
        assert "not found" in result.stderr, "Expected 'not found' message"
        print("PASS: test_handles_missing_autostart_dir")


def test_handles_chrome_beta():
    """Test that the script works with Chrome Beta paths."""
    with tempfile.TemporaryDirectory() as tmpdir:
        autostart = Path(tmpdir) / ".config" / "autostart"
        autostart.mkdir(parents=True)

        desktop_file = autostart / "chrome-beta-app.desktop"
        original_exec = "/opt/google/chrome-beta/google-chrome-beta --profile-directory=Default --app-id=xyz"
        create_desktop_file(desktop_file, original_exec)

        import os
        old_home = os.environ.get("HOME")
        os.environ["HOME"] = tmpdir
        try:
            result = run_script("/opt/google/chrome-beta/google-chrome-beta", "google-chrome-beta")
        finally:
            if old_home:
                os.environ["HOME"] = old_home
            else:
                del os.environ["HOME"]

        assert result.returncode == 0, f"Script failed: {result.stderr}"
        new_exec = read_exec_line(desktop_file)
        expected = "google-chrome-beta --profile-directory=Default --app-id=xyz"
        assert new_exec == expected, f"Unexpected Exec: {new_exec}"
        print("PASS: test_handles_chrome_beta")


if __name__ == "__main__":
    test_replaces_matching_exec()
    test_skips_non_matching_exec()
    test_dry_run_does_not_modify()
    test_handles_missing_autostart_dir()
    test_handles_chrome_beta()
    print("\nAll tests passed!")
