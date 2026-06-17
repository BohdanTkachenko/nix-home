# Display input auto-switching for a monitor shared between two PCs via a USB
# KVM switch (defaults target the LG 45GX950A, but every hardware-specific value
# is an option so another box — or another monitor — can reuse this).
#
# Runs entirely in Home Manager — no root needed: the work only reads sysfs
# (unprivileged) and calls `ddcutil setvcp` over i2c, which works without sudo
# because the user is in the `i2c` group and the host sets hardware.i2c.enable
# (both system-level, configured elsewhere).
#
# Event-driven split into two user units:
#  * monitor-input-watch.service — a tiny long-running poller. All it does is
#    sleep and check whether the monitor's USB hub is present; on a change it
#    starts the apply unit *for the right target* (active/inactive). No i2c/DDC.
#  * monitor-input-apply@.service — a templated oneshot. The instance name (%i,
#    "active" or "inactive") tells it which input to select, so it does NOT
#    re-read the hub. Runs only when triggered (by the poller, or by hand:
#    `systemctl --user start monitor-input-apply@active`). A flock serialises the
#    DDC write so two instances can't race on a rapid flip.
#
# On change: hub present -> activeInput, hub absent -> inactiveInput. The PC
# cabled to DisplayPort keeps the defaults; the PC on USB-C swaps
# activeInput/inactiveInput. apply refuses to act unless the monitor is actually
# connected (requireMonitor), so it's safe on a laptop that gets undocked.
#
# Plus `monitor-input` — a CLI to switch the panel input on demand.
#
# Input-select — confirmed working on the LG 45GX950A via cable DDC/CI:
#   ddcutil setvcp 0xF4 <val> --i2c-source-addr=0x50 --noverify
#   0xD0 = DisplayPort-1   0xD1 = USB-C   0x90 = HDMI-1   0x91 = HDMI-2   0x00 = AUTO
# Gotchas baked into the defaults below:
# - Opcode is LG's 0xF4, NOT standard 0x60 (which this panel ignores).
# - Source address MUST be 0x50 (not the standard 0x51).
# - The change is never reflected by getvcp, so --noverify is required.
{ config, lib, pkgs, ... }:

let
  cfg = config.my.hardware.kvmSwitch;
  ddc = "${pkgs.ddcutil}/bin/ddcutil";
  systemctl = "${pkgs.systemd}/bin/systemctl";

  # Minimal PATH for the scripts (date, sleep, cat, grep, flock).
  binPath = "${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:${pkgs.util-linux}/bin";

  # Per-user runtime files (shared with the CLI's `toggle`, and a switch lock).
  stateFile = ''"''${XDG_RUNTIME_DIR:-/tmp}/monitor-input.state"'';
  lockFile = ''"''${XDG_RUNTIME_DIR:-/tmp}/monitor-input.lock"'';

  # The DDC write, shared by the CLI and the apply unit (opcode + source address
  # are configurable; --noverify because this panel never reflects the change).
  setvcp = ''${ddc} setvcp ${cfg.vcp.feature} "$1" --i2c-source-addr=${cfg.vcp.sourceAddr} --noverify'';

  # Optional EDID narrowing for the monitor-connected check.
  edidMatch =
    lib.optionalString (cfg.monitorEdidMatch != "")
      ''grep -qa ${lib.escapeShellArg cfg.monitorEdidMatch} "$dir/edid" 2>/dev/null || continue'';

  # On-demand CLI: `monitor-input <target>`
  monitorInput = pkgs.writeShellScriptBin "monitor-input" ''
    set -u
    export PATH="${binPath}:$PATH"
    STATE=${stateFile}

    usage() {
      cat >&2 <<'EOF'
    monitor-input — switch the monitor input
      monitor-input pc       DisplayPort-1 (this PC)
      monitor-input usbc     USB-C (other PC)
      monitor-input hdmi1    HDMI-1
      monitor-input hdmi2    HDMI-2
      monitor-input auto     auto-select
      monitor-input toggle   flip between pc and usbc
    EOF
      exit 2
    }

    set_input() { # $1=hex value  $2=label
      if ${setvcp}; then
        echo "$2" > "$STATE" 2>/dev/null || true
        echo "→ $2"
      else
        echo "monitor-input: failed to switch to $2" >&2
        echo "  (is the monitor detected? are you in the 'i2c' group? try: ${ddc} detect)" >&2
        exit 1
      fi
    }

    [ $# -ge 1 ] || usage
    case "$1" in
      pc | dp1 | this) set_input 0xD0 "DisplayPort-1 (this PC)" ;;
      usbc | other)    set_input 0xD1 "USB-C (other PC)" ;;
      hdmi1)           set_input 0x90 "HDMI-1" ;;
      hdmi2)           set_input 0x91 "HDMI-2" ;;
      auto)            set_input 0x00 "AUTO" ;;
      toggle)
        case "$(cat "$STATE" 2>/dev/null || true)" in
          *"this PC"* | *DisplayPort*) set_input 0xD1 "USB-C (other PC)" ;;
          *)                           set_input 0xD0 "DisplayPort-1 (this PC)" ;;
        esac
        ;;
      -h | --help | help) usage ;;
      *) echo "monitor-input: unknown target '$1'" >&2; usage ;;
    esac
  '';

  # Poller: sleep, check hub presence, and on a change start the apply unit for
  # the matching target. It passes the decision (active/inactive) to apply via
  # the instance name — apply never re-reads the hub. Deliberately tiny: no i2c,
  # no DDC, no monitor check; that's apply's job.
  watchScript = pkgs.writeShellScript "monitor-input-watch" ''
    set -u
    export PATH="${binPath}:$PATH"
    INTERVAL=${toString cfg.intervalSeconds}

    hub_present() {
      for d in /sys/bus/usb/devices/*; do
        [ -r "$d/idVendor" ] && [ -r "$d/idProduct" ] || continue
        [ "$(cat "$d/idVendor"  2>/dev/null)" = "${cfg.usb.vendorId}" ]  || continue
        [ "$(cat "$d/idProduct" 2>/dev/null)" = "${cfg.usb.productId}" ] || continue
        return 0
      done
      return 1
    }

    last=unknown
    echo "monitor-input-watch started (interval ''${INTERVAL}s)"
    while :; do
      if hub_present; then target=active; else target=inactive; fi
      if [ "$target" != "$last" ]; then
        last=$target
        echo "hub presence changed -> $target, triggering apply"
        ${systemctl} --user start --no-block "monitor-input-apply@$target.service" || true
      fi
      sleep "$INTERVAL"
    done
  '';

  # Apply: switch the panel input to the target named by $1 (active|inactive),
  # passed down from the unit instance (%i). No hub recheck — the watcher already
  # decided. A flock serialises the DDC write against a concurrent instance.
  applyScript = pkgs.writeShellScript "monitor-input-apply" ''
    set -u
    export PATH="${binPath}:$PATH"
    STATE=${stateFile}
    REQUIRE_MONITOR=${if cfg.requireMonitor then "1" else "0"}

    case "''${1:-}" in
      active)   VAL="${cfg.activeInput.value}";   LABEL="${cfg.activeInput.label}" ;;
      inactive) VAL="${cfg.inactiveInput.value}"; LABEL="${cfg.inactiveInput.label}" ;;
      *) echo "usage: monitor-input-apply <active|inactive>" >&2; exit 2 ;;
    esac

    # Is an external monitor actually connected? Reads DRM status from sysfs
    # (cheap, no i2c probe); skips internal laptop panels. Optionally narrows to
    # a specific monitor by EDID substring.
    monitor_connected() {
      for s in /sys/class/drm/*/status; do
        [ "$(cat "$s" 2>/dev/null)" = "connected" ] || continue
        dir="''${s%/status}"
        name="''${dir##*/}"
        case "$name" in *eDP*|*LVDS*|*DSI*) continue ;; esac
        ${edidMatch}
        return 0
      done
      return 1
    }

    if [ "$REQUIRE_MONITOR" = 1 ] && ! monitor_connected; then
      echo "monitor not connected -> skip ($1)"
      exit 0
    fi

    # Serialise the actual DDC write so two instances can't interleave on i2c.
    exec 9>${lockFile}
    flock 9

    set -- "$VAL"   # $1 = hex value for ${setvcp}
    for i in 1 2 3 4 5; do
      if ${setvcp}; then
        echo "$LABEL" > "$STATE" 2>/dev/null || true
        echo "switched to $LABEL (attempt $i)"
        exit 0
      fi
      sleep 1
    done
    echo "FAILED to switch to $LABEL after 5 attempts" >&2
    exit 1
  '';

  inputSubmodule = lib.types.submodule {
    options = {
      value = lib.mkOption {
        type = lib.types.str;
        description = "DDC input-source value written to the VCP feature.";
      };
      label = lib.mkOption {
        type = lib.types.str;
        description = "Human label recorded to the state file / journal for this input.";
      };
    };
  };
in
{
  options.my.hardware.kvmSwitch = {
    enable = lib.mkEnableOption "auto display-input switch (a poller starts a templated oneshot that switches the panel input when the monitor's USB hub attaches/detaches)";

    intervalSeconds = lib.mkOption {
      type = lib.types.ints.positive;
      default = 2;
      description = "How often (seconds) the poller checks for the monitor's USB hub.";
    };

    usb = {
      vendorId = lib.mkOption {
        type = lib.types.str;
        default = "05e3";
        description = "USB idVendor of the monitor's built-in hub to watch (lowercase hex, no 0x).";
      };
      productId = lib.mkOption {
        type = lib.types.str;
        default = "0610";
        description = "USB idProduct of the monitor's built-in hub to watch (lowercase hex, no 0x).";
      };
    };

    vcp = {
      feature = lib.mkOption {
        type = lib.types.str;
        default = "0xF4";
        description = "DDC/CI VCP feature code for input select (LG uses 0xF4, not the standard 0x60).";
      };
      sourceAddr = lib.mkOption {
        type = lib.types.str;
        default = "0x50";
        description = "ddcutil --i2c-source-addr value (the LG needs 0x50, not the standard 0x51).";
      };
    };

    activeInput = lib.mkOption {
      type = inputSubmodule;
      default = {
        value = "0xD0";
        label = "DisplayPort-1 (this PC)";
      };
      description = "Input to select when the USB hub is present on this PC (this PC is active).";
    };

    inactiveInput = lib.mkOption {
      type = inputSubmodule;
      default = {
        value = "0xD1";
        label = "USB-C (other PC)";
      };
      description = "Input to select when the USB hub is absent (handed off to the other PC).";
    };

    requireMonitor = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Only switch when an external monitor is actually connected (so it's safe on an undocked laptop).";
    };

    monitorEdidMatch = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "ULTRAGEAR";
      description = "If set, the monitor-connected check only counts a connected output whose EDID contains this substring. Empty means any external (non-internal) output.";
    };
  };

  config = {
    # The CLI is always available (harmless on hosts without the monitor).
    home.packages = [ monitorInput ];

    # The poller (long-running) and the templated apply oneshot it triggers. User
    # services: they run in the logged-in session and need the user in the `i2c`
    # group + hardware.i2c.enable (set at the NixOS level).
    systemd.user.services.monitor-input-watch = lib.mkIf cfg.enable {
      Unit.Description = "Watch the monitor's USB hub and trigger an input switch on change";
      Service = {
        ExecStart = "${watchScript}";
        Restart = "always";
        RestartSec = 5;
      };
      Install.WantedBy = [ "default.target" ];
    };

    systemd.user.services."monitor-input-apply@" = lib.mkIf cfg.enable {
      Unit.Description = "Switch the monitor input to %i (active=${cfg.activeInput.label}, inactive=${cfg.inactiveInput.label})";
      Service = {
        Type = "oneshot";
        ExecStart = "${applyScript} %i";
        TimeoutStartSec = 30;
      };
      # No Install/WantedBy: started on demand by the poller (or by hand).
    };
  };
}
