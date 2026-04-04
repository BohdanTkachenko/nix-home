# Custom YubiKey touch notifier with command info and persistent notification
{ pkgs, ... }:

let
  notifier = pkgs.writeScript "yubikey-touch-notifier" ''
    #!${pkgs.python3.withPackages (ps: [ ps.pygobject3 ])}/bin/python3
    import os, signal, socket, sys, glob, threading, time
    from gi.repository import Gio, GLib

    class YubiKeyNotifier(Gio.Application):
        def __init__(self):
            super().__init__(
                application_id="yubikey.touch.notifier",
                flags=Gio.ApplicationFlags.FLAGS_NONE,
            )
            self.active_notification = False
            self.sudo_pids = []
            self.started = False

        def do_startup(self):
            Gio.Application.do_startup(self)
            action = Gio.SimpleAction.new("cancel", None)
            action.connect("activate", self.on_cancel)
            self.add_action(action)

        def do_activate(self):
            if not self.started:
                self.started = True
                thread = threading.Thread(target=self.listen_socket, daemon=True)
                thread.start()
                self.hold()

        def on_cancel(self, action, param):
            for pid in self.sudo_pids:
                try:
                    os.kill(pid, signal.SIGTERM)
                except (ProcessLookupError, PermissionError):
                    pass
            self.sudo_pids = []
            self.dismiss_notification()

        # Process names to skip or rename for cleaner display
        SKIP_PROCS = {"bash", "fish", "zsh", "sh", "dash", "sudo"}
        RENAME_PROCS = {
            ".ptyxis-wrapped": "Ptyxis",
            "ptyxis": "Ptyxis",
            ".ptyxis-agent-w": None,  # skip
            "gnome-terminal-": "Terminal",
            "gnome-terminal-server": "Terminal",
            "alacritty": "Alacritty",
            "kitty": "Kitty",
            "wezterm-gui": "WezTerm",
        }

        def get_process_chain(self, pid):
            """Walk up the process tree to find the originating application."""
            chain = []
            current = str(pid)
            seen = set()
            while True:
                if current in seen:
                    break
                seen.add(current)
                try:
                    with open(f"/proc/{current}/comm") as f:
                        name = f.read().strip()
                    if name in ("systemd", "init") or current in ("1", "0"):
                        break
                    # Apply renaming
                    if name in self.RENAME_PROCS:
                        renamed = self.RENAME_PROCS[name]
                        if renamed is not None:
                            chain.append(renamed)
                    elif name not in self.SKIP_PROCS:
                        chain.append(name)
                    with open(f"/proc/{current}/status") as f:
                        for line in f:
                            if line.startswith("PPid:"):
                                current = line.split(":")[1].strip()
                                break
                        else:
                            break
                except (OSError, IOError, PermissionError):
                    break
            chain.reverse()
            # Deduplicate consecutive entries
            deduped = []
            for name in chain:
                if not deduped or deduped[-1] != name:
                    deduped.append(name)
            return deduped

        def find_pending_sudos(self):
            """Find all sudo processes without children (still waiting for auth)."""
            results = []
            for pid_dir in glob.glob("/proc/[0-9]*"):
                try:
                    pid = os.path.basename(pid_dir)
                    with open(f"/proc/{pid}/comm") as f:
                        comm = f.read().strip()
                    if comm != "sudo":
                        continue
                    # Check if process has children (already authenticated)
                    try:
                        with open(f"/proc/{pid}/task/{pid}/children") as f:
                            if f.read().strip():
                                continue
                    except (OSError, IOError):
                        pass
                    with open(f"/proc/{pid}/cmdline", "rb") as f:
                        args = f.read().decode("utf-8", errors="replace").split("\0")
                    # Skip "sudo" and its flags, find the actual command
                    cmd_start = 1
                    for i, arg in enumerate(args[1:], 1):
                        if not arg.startswith("-") and arg != "":
                            cmd_start = i
                            break
                    cmd = " ".join(a for a in args[cmd_start:] if a)
                    if cmd:
                        chain = self.get_process_chain(pid)
                        # Remove "sudo" from end of chain since we show the command separately
                        if chain and chain[-1] == "sudo":
                            chain = chain[:-1]
                        origin = " → ".join(chain) if chain else "unknown"
                        results.append((int(pid), cmd, origin))
                except (OSError, IOError, PermissionError):
                    continue
            return results

        def find_ssh_sessions(self):
            """Find ssh client processes with parseable destinations."""
            sessions = set()
            for pid_dir in glob.glob("/proc/[0-9]*"):
                try:
                    pid = os.path.basename(pid_dir)
                    with open(f"/proc/{pid}/comm") as f:
                        if f.read().strip() != "ssh":
                            continue
                    # Parse destination from cmdline
                    with open(f"/proc/{pid}/cmdline", "rb") as f:
                        args = [a for a in f.read().decode("utf-8", errors="replace").split("\0") if a]
                    if len(args) < 2:
                        continue
                    dest = None
                    skip_next = False
                    # SSH options that take an argument
                    opts_with_arg = set("bcDEeFIiJLlmOopQRSWw")
                    for arg in args[1:]:
                        if skip_next:
                            skip_next = False
                            continue
                        if arg.startswith("-") and len(arg) >= 2 and arg[1] in opts_with_arg:
                            if len(arg) == 2:
                                skip_next = True
                            continue
                        if not arg.startswith("-"):
                            dest = arg
                            break
                    if dest:
                        # Strip user@ prefix if present
                        if "@" in dest:
                            dest = dest.split("@", 1)[1]
                        sessions.add(dest)
                except (OSError, IOError, PermissionError):
                    continue
            return sorted(sessions)

        def show_notification(self, source="U2F"):
            notification = Gio.Notification.new("Touch your YubiKey")
            self.sudo_pids = []

            if source == "GPG":
                body = "GPG signing"
            else:
                # U2F or SSH — look for both local sudos and SSH sessions
                lines = []
                pending = self.find_pending_sudos()
                self.sudo_pids = [pid for pid, _, _ in pending]
                for _, cmd, origin in pending:
                    lines.append(f"{origin} → sudo {cmd}")

                ssh_sessions = self.find_ssh_sessions()
                for host in ssh_sessions:
                    lines.append(f"SSH: {host}")

                if not lines:
                    body = "Authentication requested"
                elif len(lines) == 1:
                    body = lines[0]
                else:
                    body = "\n".join(f"• {line}" for line in lines)

                if self.sudo_pids:
                    notification.set_default_action("app.cancel")
                    notification.add_button("Cancel", "app.cancel")

            notification.set_body(body)
            notification.set_icon(Gio.ThemedIcon.new("dialog-password"))
            notification.set_priority(Gio.NotificationPriority.URGENT)
            GLib.idle_add(self.send_notification, "yubikey-touch", notification)
            self.active_notification = True

        def dismiss_notification(self):
            if self.active_notification:
                GLib.idle_add(self.withdraw_notification, "yubikey-touch")
                self.active_notification = False
                self.sudo_pids = []

        def listen_socket(self):
            sock_path = os.path.join(
                os.environ.get("XDG_RUNTIME_DIR", ""), "yubikey-touch-detector.socket"
            )
            while True:
                try:
                    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
                    sock.connect(sock_path)
                    while True:
                        data = sock.recv(1024)
                        if not data:
                            break
                        msg = data.decode("utf-8", errors="replace").strip()
                        if msg.endswith("_1"):
                            source = msg.split("_")[0]
                            self.show_notification(source)
                        elif msg.endswith("_0"):
                            self.dismiss_notification()
                except (ConnectionRefusedError, FileNotFoundError):
                    time.sleep(5)
                except Exception as e:
                    print(f"Error: {e}", file=sys.stderr)
                    time.sleep(5)

    app = YubiKeyNotifier()
    app.run([])
  '';
in
{
  home.packages = [
    (pkgs.makeDesktopItem {
      name = "yubikey.touch.notifier";
      desktopName = "YubiKey";
      exec = "${notifier}";
      noDisplay = true;
      extraConfig.DBusActivatable = "true";
    })
  ];

  systemd.user.services.yubikey-touch-notifier = {
    Unit = {
      Description = "YubiKey touch notifier with command info";
      After = [ "graphical-session.target" "yubikey-touch-detector.socket" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${notifier}";
      Restart = "on-failure";
      RestartSec = "5s";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
