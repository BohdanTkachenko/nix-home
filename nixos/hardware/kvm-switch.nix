# Automatic display input switching based on USB hub connection
# When the USB hub (05e3:0610) connects, switch monitor to DisplayPort-1 (this PC)
# When it disconnects, switch to USB-C (other PC)
#
# LG ULTRAGEAR+ uses non-standard DDC/CI:
# - Feature 0xF4 for input switching
# - I2C address 0x50 instead of standard 0x51
# - Input values: 0xD0=DP1, 0xD1=USB-C, 0x90=HDMI1, 0x91=HDMI2
{ pkgs, ... }:

let
  switchScript = pkgs.writeShellScript "kvm-display-switch" ''
    export PATH="${pkgs.ddcutil}/bin:$PATH"

    ACTION="$1"
    LOGFILE="/tmp/kvm-switch.log"

    echo "$(date): KVM switch triggered with action: $ACTION" >> "$LOGFILE"

    case "$ACTION" in
      add)
        # USB hub connected - switch to this PC (DisplayPort-1)
        ddcutil setvcp 0xF4 0xD0 --i2c-source-addr=0x50 --noverify 2>> "$LOGFILE" && \
          echo "$(date): Switched to DisplayPort-1 (this PC)" >> "$LOGFILE"
        ;;
      remove)
        # USB hub disconnected - switch to other PC (USB-C)
        ddcutil setvcp 0xF4 0xD1 --i2c-source-addr=0x50 --noverify 2>> "$LOGFILE" && \
          echo "$(date): Switched to USB-C (other PC)" >> "$LOGFILE"
        ;;
      *)
        echo "$(date): Unknown action: $ACTION" >> "$LOGFILE"
        ;;
    esac
  '';
in
{
  services.udev.extraRules = ''
    # KVM display switch on USB hub connect/disconnect
    # Genesys Logic Hub (05e3:0610)
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="05e3", ATTR{idProduct}=="0610", RUN+="${switchScript} add"
    ACTION=="remove", SUBSYSTEM=="usb", ENV{ID_VENDOR_ID}=="05e3", ENV{ID_MODEL_ID}=="0610", RUN+="${switchScript} remove"
  '';
}
