# LG 45GX950A display input switching.
#
# Two things live here:
#  1. `monitor-input` — a global CLI to switch the panel's input on demand.
#  2. A udev rule that auto-switches when the monitor's built-in USB hub
#     (Genesys Logic 05e3:0610, on a physical USB switch shared with the other
#     PC) attaches/detaches: attach -> this PC (DP-1), detach -> other PC (USB-C).
#
# Input-select — confirmed working on this hardware via cable DDC/CI:
#   ddcutil setvcp 0xF4 <val> --i2c-source-addr=0x50 --noverify
#   0xD0 = DisplayPort-1 (this PC)   0xD1 = USB-C (other PC)
#   0x90 = HDMI-1   0x91 = HDMI-2   0x00 = AUTO
# Gotchas baked into the choices below:
# - Opcode is LG's 0xF4, NOT standard 0x60 (which this panel ignores).
# - Source address MUST be 0x50 (not the standard 0x51).
# - The change is never reflected by getvcp, so --noverify is required.
# - No-sudo access relies on the user being in the `i2c` group (see user.nix)
#   and hardware.i2c.enable (see common.nix).
# - udev `remove` events for USB carry NO ID_VENDOR_ID/ID_MODEL_ID (those are
#   added by usb_id on `add` only) — so the remove rule matches ENV{PRODUCT},
#   which IS present on both add and remove ("5e3/610/<bcd>", no leading zeros).
{ pkgs, ... }:

let
  ddc = "${pkgs.ddcutil}/bin/ddcutil";
  # Shared, world-writable (created by systemd-tmpfiles below) so both the
  # root udev handler and the user CLI can record the last input for `toggle`.
  stateFile = "/run/monitor-input.state";

  # Minimal PATH for things spawned by udev/systemd-run (date, sleep, chmod, cat).
  binPath = "${pkgs.coreutils}/bin";

  # On-demand CLI: `monitor-input <target>`
  monitorInput = pkgs.writeShellScriptBin "monitor-input" ''
    set -u
    export PATH="${binPath}:$PATH"
    STATE=${stateFile}

    usage() {
      cat >&2 <<'EOF'
    monitor-input — switch the LG 45GX950A input
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
      if ${ddc} setvcp 0xF4 "$1" --i2c-source-addr=0x50 --noverify; then
        echo "$2" > "$STATE" 2>/dev/null || true
        echo "→ $2"
      else
        echo "monitor-input: failed to switch to $2" >&2
        echo "  (is the LG detected? are you in the 'i2c' group? try: ${ddc} detect)" >&2
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

  # udev handler for the monitor's USB hub attach/detach.
  switchScript = pkgs.writeShellScript "kvm-display-switch" ''
    set -u
    export PATH="${binPath}:$PATH"
    export HOME="''${HOME:-/root}"   # let ddcutil find a cache dir (silences warnings)
    LOG=/tmp/kvm-switch.log
    STATE=${stateFile}

    case "$1" in
      add)    VAL=0xD0; NAME="DisplayPort-1 (this PC)" ;;
      remove) VAL=0xD1; NAME="USB-C (other PC)" ;;
      *) echo "$(date): unknown action $1" >> "$LOG"; exit 0 ;;
    esac

    echo "$(date): $1 -> switching to $NAME" >> "$LOG"
    # The DP-AUX i2c bus can be momentarily busy right after the USB event; retry.
    for i in 1 2 3 4 5; do
      if ${ddc} setvcp 0xF4 "$VAL" --i2c-source-addr=0x50 --noverify >> "$LOG" 2>&1; then
        echo "$NAME" > "$STATE" 2>/dev/null || true
        echo "$(date): switched to $NAME (attempt $i)" >> "$LOG"
        exit 0
      fi
      sleep 1
    done
    echo "$(date): FAILED to switch to $NAME after 5 attempts" >> "$LOG"
  '';
in
{
  environment.systemPackages = [ monitorInput ];

  # Shared toggle-state file, writable by both root (udev) and the user (CLI).
  systemd.tmpfiles.rules = [ "f ${stateFile} 0666 root root -" ];

  # Launch the auto-switch from a transient systemd unit (systemd-run --no-block)
  # instead of running ddcutil directly in RUN+=: udev serializes its event queue
  # and kills slow RUN children, and ddcutil detect+write takes a second or two.
  # No fixed --unit name: the two nested 05e3:0610 hubs fire together, and a fixed
  # name would collide ("unit already exists"); auto-generated names don't.
  services.udev.extraRules = ''
    # KVM display switch on the monitor's USB hub connect/disconnect (Genesys Logic 05e3:0610)
    # add: ATTR is available (device present). remove: match ENV{PRODUCT} — ID_VENDOR_ID is absent on remove.
    ACTION=="add",    SUBSYSTEM=="usb", ATTR{idVendor}=="05e3", ATTR{idProduct}=="0610", RUN+="${pkgs.systemd}/bin/systemd-run --no-block --collect ${switchScript} add"
    ACTION=="remove", SUBSYSTEM=="usb", ENV{PRODUCT}=="5e3/610/*",                        RUN+="${pkgs.systemd}/bin/systemd-run --no-block --collect ${switchScript} remove"
  '';
}
