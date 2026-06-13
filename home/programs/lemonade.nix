{ config, lib, pkgs, ... }:
# Remote clipboard / browser bridge over SSH, using lemonade
# (https://github.com/lemonade-command/lemonade). The headless cloudtop
# (workbench) runs the *client*: an `xdg-open` shim and `$BROWSER` route every
# URL-open to `lemonade open`, which reaches the *server* on the local PC
# (nyancat) over an SSH reverse tunnel (RemoteForward 2489, see ssh/default.nix)
# and opens it in the real browser there. The same channel carries clipboard
# (`lemonade copy`/`paste`).
let
  cfg = config.my.lemonade;
  port = 2489;

  # workbench has no xdg-open of its own, so this shim has no collision and is
  # what Claude Code (and anything else) calls to open a URL. Forward it all to
  # the local machine's browser via the reverse tunnel.
  remoteXdgOpen = pkgs.writeShellApplication {
    name = "xdg-open";
    runtimeInputs = [ pkgs.lemonade ];
    text = ''
      exec lemonade open --port ${toString port} "$@"
    '';
  };

  # Pipe stdin to the local machine's clipboard via lemonade. With no piped
  # input, copies the latest Claude Code `/copy` output file — Claude's own
  # `/copy` emits OSC 52, which Ptyxis/VTE does not honor, so this is the
  # working path on this terminal.
  clip = pkgs.writeShellApplication {
    name = "clip";
    runtimeInputs = [
      pkgs.lemonade
      pkgs.coreutils
    ];
    text = ''
      if [ -t 0 ]; then
        f="/tmp/claude-$(id -u)/response.md"
        if [ -f "$f" ]; then
          lemonade copy --port ${toString port} < "$f"
          echo "clip: copied $(wc -c < "$f") bytes from $f to the local clipboard" >&2
        else
          echo "usage: <command> | clip   (pipe text), or run after Claude's /copy" >&2
          exit 1
        fi
      else
        lemonade copy --port ${toString port}
      fi
    '';
  };
in
{
  config = lib.mkMerge [
    (lib.mkIf cfg.client.enable {
      home.packages = [
        pkgs.lemonade
        remoteXdgOpen
        clip
      ];
      # Tools that consult $BROWSER (rather than calling xdg-open) also reach
      # the local browser.
      home.sessionVariables.BROWSER = lib.getExe remoteXdgOpen;
    })

    (lib.mkIf cfg.server.enable {
      home.packages = [ pkgs.lemonade ];

      systemd.user.services.lemonade = {
        Unit = {
          Description = "lemonade remote clipboard/browser server";
          After = [ "graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
        };
        Install.WantedBy = [ "graphical-session.target" ];
        Service = {
          # The port is bound on all interfaces, but --allow restricts callers
          # to loopback — i.e. only the SSH reverse tunnel can reach it.
          ExecStart = "${pkgs.lemonade}/bin/lemonade server --port ${toString port} --allow 127.0.0.1/32,::1/128";
          Restart = "on-failure";
          RestartSec = 5;
          # lemonade shells out to a browser opener (xdg-open) and an X
          # clipboard tool (xsel); on Wayland these reach the session via
          # XWayland clipboard bridging.
          Environment = [
            "PATH=${lib.makeBinPath [
              pkgs.xdg-utils
              pkgs.xsel
              pkgs.coreutils
            ]}"
          ];
        };
      };
    })
  ];
}
