# lg-usb-ddc

Send DDC/CI commands to an LG monitor **through the Realtek RTS5411 USB hub's vendor HID
interface**, instead of over the display cable's DDC channel. This replicates what LG
Switch.app does via its `iUSB2I2C.framework`. Use it when the panel (e.g. LG UltraGear
45GX950A) ignores input-source switching over cable DDC/CI but obeys it through the USB hub.

See [`PROTOCOL.md`](./PROTOCOL.md) for the byte-exact, disassembly-cited protocol.

## What it does

For one transaction the tool replicates LG's exact call order:

```
VendorCmdEnable(1)                 ; HID report: 40 02 01 00 DA 0B 00 00  (+pad to 192)
ConfigAddr(addr=0x6E, value=1, sp=1) ; HID report: 40 F6 01 6E 81 80 00 00
WriteI2C(slave, payload)           ; HID report: 40 C6 <slave LE32> <len LE16>  + payload@0x40
```

Each report is a **192-byte HID OUTPUT report, report-id 0** (on Linux/hidapi a `0x00`
report-id byte is prepended, so 193 bytes are written). The I2C data payload lives at byte
offset 0x40 inside the report.

The DDC `Set VCP` body is `[0x84, 0x03, <vcp>, 0x00, <value>, checksum]`, where
`checksum = 0x6E ^ source ^ 0x84 ^ 0x03 ^ <vcp> ^ 0x00 ^ <value>`. LG passes the DDC source
byte as the WriteI2C *slave* argument (not inside the payload); `--source-in-payload`
switches to the alternate framing.

## Build

```bash
cd lg-usb-ddc
UDEV_DEV=$(dirname $(find /nix/store -name libudev.pc -path '*pkgconfig*' | head -1))
UDEV_BASE=${UDEV_DEV%/lib/pkgconfig}
nix shell nixpkgs#cargo nixpkgs#rustc nixpkgs#pkg-config nixpkgs#udev nixpkgs#gcc -c \
  env PKG_CONFIG_PATH=$UDEV_DEV CFLAGS="-I$UDEV_BASE/include" CPATH="$UDEV_BASE/include" \
  cargo build --release
```

The crate uses hidapi 2.x with the bundled `linux-static-hidraw` backend (no system hidapi
needed) but hidapi-rs still links `libudev` and needs `libudev.h` at compile time — hence
`nixpkgs#udev` plus the `PKG_CONFIG_PATH`/`CFLAGS`/`CPATH` above. The resulting binary is at
`target/release/lg-usb-ddc`.

> On the x86_64 desktop, the same command works; substitute the desktop's nixpkgs. If you
> prefer not to depend on libudev at all, hidapi-rs also has a `linux-static-libusb` backend
> (set `features = ["linux-static-libusb"]` in `Cargo.toml`); that backend talks to the
> device through libusb and may need the kernel hidraw/usbhid driver detached.

## Usage

```bash
lg-usb-ddc list                       # enumerate all 0x0bda HID interfaces
lg-usb-ddc switch dp1                  # SetVCP 0x60 = 0xD0 (LG alt)
lg-usb-ddc --vcp 0xf4 switch dp1       # SetVCP 0xF4 (LG UltraGear+ feature - try this first)
lg-usb-ddc --standard switch hdmi1     # use standard MCCS values
lg-usb-ddc switch 0xd2                 # raw VCP value
lg-usb-ddc raw-i2c --slave 0x51 --data "84 03 60 00 d0"   # arbitrary I2C (checksum NOT added)
lg-usb-ddc getvcp 0x60                 # read a VCP for verification
lg-usb-ddc --verbose switch dp1        # hexdump every report
```

Inputs: `dp1 dp2 hdmi1 hdmi2 usbc`. Values (default = LG alt):

| input | alt   | standard |
| ----- | ----- | -------- |
| dp1   | 0xD0  | 0x0F     |
| dp2   | 0xD1  | 0x10     |
| hdmi1 | 0x90  | 0x11     |
| hdmi2 | 0x91  | 0x12     |
| usbc  | 0xD2  | 0xD2     |

Note: `raw-i2c --data` sends the bytes verbatim (you supply your own checksum); `switch` and
`getvcp` compute the DDC checksum for you.

### Things to try on real hardware (in order)

1. `lg-usb-ddc list` — confirm the Realtek hub HID interface shows up; note its path/PID.
2. `lg-usb-ddc --verbose --vcp 0xf4 switch dp1` — LG UltraGear+ uses feature **0xF4** with
   source `0x50` for input switching (matches the old ddcutil rule). This is the most likely
   to work for the 45GX950A.
3. If nothing happens, try `--vcp 0x60` (standard input-select), `--source-in-payload`, and
   `--source-addr 0x51` (LG Switch's probes used 0x51).
4. `lg-usb-ddc getvcp 0x60` to read back the current input and confirm.

See `PROTOCOL.md` section 9 for the full list of hardware uncertainties.

## udev rule (access to /dev/hidraw for vendor 0x0bda)

Create `/etc/udev/rules.d/70-lg-usb-ddc.rules`:

```
# Realtek RTS5411 hub vendor HID interface - allow user access for lg-usb-ddc
KERNEL=="hidraw*", ATTRS{idVendor}=="0bda", MODE="0660", TAG+="uaccess"
```

`TAG+="uaccess"` grants the logged-in user access; or use `GROUP="plugdev", MODE="0660"` and
add yourself to `plugdev`. Reload with `sudo udevadm control --reload && sudo udevadm trigger`.

On NixOS, add to your config:

```nix
services.udev.extraRules = ''
  KERNEL=="hidraw*", ATTRS{idVendor}=="0bda", MODE="0660", TAG+="uaccess"
'';
```

## Wiring into nixos/hardware/kvm-switch.nix

The existing module calls `ddcutil setvcp 0xF4 ... --i2c-source-addr=0x50` over the cable.
To route through the USB bridge instead, build the tool as a package and replace the ddcutil
calls. Example replacement for the script body in `nixos/hardware/kvm-switch.nix`:

```nix
{ pkgs, ... }:
let
  # however you package it - e.g. pkgs.rustPlatform.buildRustPackage from this crate,
  # or a flake input. Placeholder name:
  lg-usb-ddc = pkgs.callPackage ./pkgs/lg-usb-ddc.nix { };

  switchScript = pkgs.writeShellScript "kvm-display-switch" ''
    LOGFILE="/tmp/kvm-switch.log"
    echo "$(date): KVM switch triggered with action: $1" >> "$LOGFILE"
    case "$1" in
      add)    ${lg-usb-ddc}/bin/lg-usb-ddc --vcp 0xf4 switch dp1 2>> "$LOGFILE" \
                && echo "$(date): -> DisplayPort-1 (this PC)" >> "$LOGFILE" ;;
      remove) ${lg-usb-ddc}/bin/lg-usb-ddc --vcp 0xf4 switch usbc 2>> "$LOGFILE" \
                && echo "$(date): -> USB-C (other PC)" >> "$LOGFILE" ;;
      *) echo "$(date): unknown action $1" >> "$LOGFILE" ;;
    esac
  '';
in {
  # keep the existing trigger rule, plus the hidraw access rule:
  services.udev.extraRules = ''
    KERNEL=="hidraw*", ATTRS{idVendor}=="0bda", MODE="0660", TAG+="uaccess"
    ACTION=="add",    SUBSYSTEM=="usb", ATTR{idVendor}=="05e3", ATTR{idProduct}=="0610", RUN+="${switchScript} add"
    ACTION=="remove", SUBSYSTEM=="usb", ENV{ID_VENDOR_ID}=="05e3", ENV{ID_MODEL_ID}=="0610", RUN+="${switchScript} remove"
  '';
}
```

A minimal `pkgs/lg-usb-ddc.nix`:

```nix
{ rustPlatform, pkg-config, udev }:
rustPlatform.buildRustPackage {
  pname = "lg-usb-ddc";
  version = "0.1.0";
  src = ./.;                       # path to this crate
  cargoLock.lockFile = ./Cargo.lock;
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ udev ];          # hidapi-rs links libudev
}
```

> udev runs `RUN+=` actions as root, so the hidraw `uaccess`/group permissions only matter
> for running `lg-usb-ddc` interactively as your user. The udev-triggered script already runs
> privileged.
