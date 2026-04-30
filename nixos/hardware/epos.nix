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

    HP_SINK="alsa_output.usb-GeneralPlus_USB_Audio_Device-00.analog-stereo"
    HP_SOURCE="alsa_input.usb-GeneralPlus_USB_Audio_Device-00.mono-fallback"
    SB_SINK="alsa_output.usb-C-Media_Electronics_Inc._USB_Audio_Device-00.analog-stereo"
    SB_SOURCE="alsa_input.usb-046d_Logitech_BRIO_827A05B4-03.analog-stereo"

    current_sink=$($PACTL get-default-sink)
    if [ "$current_sink" = "$HP_SINK" ]; then
      $PACTL set-default-sink "$SB_SINK"
      $PACTL set-default-source "$SB_SOURCE"
    else
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
  };
}
