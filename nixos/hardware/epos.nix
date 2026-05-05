# EPOS / Sennheiser gaming audio support
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.hardware.epos;

  toggleAudio = pkgs.writeShellScript "epos-toggle-audio" ''
    set -eu
    PACTL="${pkgs.pulseaudio}/bin/pactl"

    HP_SINK_RE='^alsa_output\.usb-Sennheiser_EPOS_GSX_300_.*-00\.analog-stereo$'
    HP_SOURCE_RE='^alsa_input\.usb-Sennheiser_EPOS_GSX_300_.*-00\.mono-fallback$'
    SB_SINK="alsa_output.usb-C-Media_Electronics_Inc._USB_Audio_Device-00.analog-stereo"
    SB_SOURCE="alsa_input.usb-046d_Logitech_BRIO_827A05B4-03.analog-stereo"

    HP_SINK=$($PACTL list short sinks | ${pkgs.gawk}/bin/awk -v re="$HP_SINK_RE" '$2 ~ re { print $2; exit }')
    HP_SOURCE=$($PACTL list short sources | ${pkgs.gawk}/bin/awk -v re="$HP_SOURCE_RE" '$2 ~ re { print $2; exit }')

    current_sink=$($PACTL get-default-sink)
    if [ -n "$HP_SINK" ] && [ "$current_sink" = "$HP_SINK" ]; then
      $PACTL set-default-sink "$SB_SINK"
      $PACTL set-default-source "$SB_SOURCE"
    elif [ -n "$HP_SINK" ] && [ -n "$HP_SOURCE" ]; then
      $PACTL set-default-sink "$HP_SINK"
      $PACTL set-default-source "$HP_SOURCE"
    fi
  '';

  reader = pkgs.writers.writePython3 "epos-smart-button-reader" {
    flakeIgnore = [ "E501" ];
  } ''
    import subprocess
    import sys
    import time

    DEV = "/dev/epos-gsx-smartbutton"
    SH = "${pkgs.bash}/bin/sh"
    REPORT_SMART_BUTTON_PRESS = b"\x02\x01"


    def run_action(cmd):
        try:
            subprocess.run([SH, "-c", cmd], check=False)
        except Exception as e:
            print(f"action failed: {e}", file=sys.stderr, flush=True)


    def main():
        cmd = sys.argv[1] if len(sys.argv) > 1 else "true"
        while True:
            try:
                with open(DEV, "rb", buffering=0) as f:
                    while True:
                        data = f.read(64)
                        if not data:
                            break
                        if data[:2] == REPORT_SMART_BUTTON_PRESS:
                            run_action(cmd)
            except FileNotFoundError:
                time.sleep(5)
            except OSError as e:
                print(f"read error: {e}", file=sys.stderr, flush=True)
                time.sleep(2)


    if __name__ == "__main__":
        main()
  '';

  volumeRedirect = pkgs.writers.writePython3 "epos-volume-redirect" {
    flakeIgnore = [ "E501" ];
  } ''
    import re
    import subprocess
    import sys
    import time

    PACTL = "${pkgs.pulseaudio}/bin/pactl"
    EPOS_SINK_RE = re.compile(r'^alsa_output\.usb-Sennheiser_EPOS_GSX_300_.*-00\.analog-stereo$')
    SINK_EVENT_RE = re.compile(r"Event 'change' on sink #(\d+)")
    VOLUME_RE = re.compile(r':\s*(\d+)\s*/')
    MAX_VOL = 65536


    def pactl(*args):
        try:
            return subprocess.run(
                [PACTL, *args], check=False, capture_output=True, text=True,
            ).stdout
        except Exception as e:
            print(f"pactl error: {e}", file=sys.stderr, flush=True)
            return ""


    def list_sinks():
        sinks = []
        for line in pactl("list", "short", "sinks").splitlines():
            parts = line.split("\t")
            if len(parts) >= 2:
                try:
                    sinks.append((int(parts[0]), parts[1]))
                except ValueError:
                    pass
        return sinks


    def find_epos_sink():
        for idx, name in list_sinks():
            if EPOS_SINK_RE.match(name):
                return idx, name
        return None, None


    def get_sink_volume(sink):
        m = VOLUME_RE.search(pactl("get-sink-volume", sink))
        return int(m.group(1)) if m else None


    def set_sink_volume(sink, value):
        value = max(0, min(int(value), MAX_VOL))
        subprocess.run(
            [PACTL, "set-sink-volume", sink, str(value)], check=False,
        )


    def watch(epos_idx, epos_name, last_vol):
        proc = subprocess.Popen(
            [PACTL, "subscribe"], stdout=subprocess.PIPE, text=True, bufsize=1,
        )
        try:
            for line in proc.stdout:
                m = SINK_EVENT_RE.match(line)
                if not m or int(m.group(1)) != epos_idx:
                    continue
                new_vol = get_sink_volume(epos_name)
                if new_vol is None or new_vol == last_vol:
                    continue
                last_vol = new_vol
                for idx, name in list_sinks():
                    if idx == epos_idx:
                        continue
                    other_vol = get_sink_volume(name)
                    if other_vol is not None and other_vol != new_vol:
                        set_sink_volume(name, new_vol)
        finally:
            proc.terminate()


    def main():
        while True:
            epos_idx, epos_name = find_epos_sink()
            if epos_idx is None:
                time.sleep(5)
                continue
            last_vol = get_sink_volume(epos_name)
            if last_vol is None:
                time.sleep(5)
                continue
            try:
                watch(epos_idx, epos_name, last_vol)
            except Exception as e:
                print(f"watch error: {e}", file=sys.stderr, flush=True)
            time.sleep(2)


    if __name__ == "__main__":
        main()
  '';
in
{
  options.my.hardware.epos = {
    enable = lib.mkEnableOption "EPOS gaming audio support";

    smartButtonAction = lib.mkOption {
      type = lib.types.str;
      default = "${toggleAudio}";
      description = ''
        Shell command to run when the GSX 300 Smart Button is pressed.
        The command is executed via `sh -c` in the user's session.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Allow hidraw access for EPOS Gaming Suite (running under Wine) to
    # configure the device's smart button, surround mode, EQ, etc., and
    # expose a stable symlink for the smart-button reader.
    services.udev.extraRules = ''
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1395", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1395", ATTRS{idProduct}=="0098", SYMLINK+="epos-gsx-smartbutton"
    '';

    systemd.user.services.epos-smart-button = {
      description = "Bind EPOS GSX 300 Smart Button to a user action";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = "${reader} ${lib.escapeShellArg cfg.smartButtonAction}";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };

    systemd.user.services.epos-volume-redirect = {
      description = "Redirect EPOS GSX 300 hardware volume knob to the default sink";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      after = [
        "graphical-session.target"
        "pipewire-pulse.service"
      ];
      serviceConfig = {
        ExecStart = "${volumeRedirect}";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };
}
