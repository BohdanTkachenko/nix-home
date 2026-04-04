# Replace image bytes with a file path on the clipboard after a GNOME screenshot.
#
# GNOME Shell's screenshot "Copy to Clipboard" puts raw image/png bytes on the
# Wayland clipboard. Claude Code running inside a terminal (Ptyxis) can't read
# image bytes from the clipboard — but it can read a pasted file path. So this
# service watches ~/Pictures/Screenshots and, when a new image appears AND the
# clipboard currently holds image data (meaning the user pressed "Copy to
# Clipboard" in the screenshot UI), replaces the clipboard with the file path.
{ config, lib, pkgs, ... }:

let
  watcher = pkgs.writeShellScript "screenshot-path-clipboard" ''
    set -eu
    dir="$HOME/Pictures/Screenshots"
    mkdir -p "$dir"

    ${pkgs.inotify-tools}/bin/inotifywait -qm \
      -e close_write -e moved_to \
      --format '%w%f' \
      "$dir" | while IFS= read -r file; do
      case "$file" in
        *.png|*.jpg|*.jpeg|*.webp) ;;
        *) continue ;;
      esac

      # Give GNOME a moment to populate the clipboard after saving the file.
      sleep 0.3

      # Only replace the clipboard if it currently holds image data, i.e. the
      # user clicked "Copy to Clipboard" in GNOME's screenshot UI. This avoids
      # stomping the clipboard for save-only screenshot workflows.
      if ${pkgs.wl-clipboard}/bin/wl-paste --list-types 2>/dev/null \
           | ${pkgs.gnugrep}/bin/grep -q '^image/'; then
        printf '%s' "$file" | ${pkgs.wl-clipboard}/bin/wl-copy
      fi
    done
  '';
in
{
  config = lib.mkIf config.my.screenshotPathClipboard.enable {
    home.packages = with pkgs; [
      inotify-tools
      wl-clipboard
    ];

    systemd.user.services.screenshot-path-clipboard = {
      Unit = {
        Description = "Replace screenshot image on clipboard with its file path";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${watcher}";
        Restart = "on-failure";
        RestartSec = "5s";
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
