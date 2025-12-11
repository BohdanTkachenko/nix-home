# LG ULTRAGEAR+ DDC/CI Control

Documentation of DDC/CI commands discovered for the LG ULTRAGEAR+ monitor (GSM model, Product code: 40605).

## Key Findings

LG monitors use **non-standard DDC/CI**:
- Standard DDC/CI address `0x51` works for some features
- Input switching requires alternate address `0x50`
- Feature code `0xF4` for input (not standard `0x60`)
- PIP controls are not accessible via DDC/CI (requires USB HID)

## Working Commands

### Input Switching (requires `--i2c-source-addr=0x50`)

| Input | Command |
|-------|---------|
| DisplayPort 1 | `ddcutil setvcp 0xF4 0xD0 --i2c-source-addr=0x50 --noverify` |
| USB-C | `ddcutil setvcp 0xF4 0xD1 --i2c-source-addr=0x50 --noverify` |
| HDMI 1 | `ddcutil setvcp 0xF4 0x90 --i2c-source-addr=0x50 --noverify` |
| HDMI 2 | `ddcutil setvcp 0xF4 0x91 --i2c-source-addr=0x50 --noverify` |

Note: `--noverify` is required because LG doesn't report back properly.

### PBP (Picture-by-Picture) - Standard address works

| Mode | Command |
|------|---------|
| Off | `ddcutil setvcp 0xD7 0x01` |
| 50/50 split | `ddcutil setvcp 0xD7 0x05` |

### Other Standard Controls

| Feature | VCP Code | Example |
|---------|----------|---------|
| Brightness | 0x10 | `ddcutil setvcp 0x10 50` |
| Contrast | 0x12 | `ddcutil setvcp 0x12 70` |
| Volume | 0x62 | `ddcutil setvcp 0x62 30` |
| Color Preset | 0x14 | `ddcutil setvcp 0x14 0x0b` (User 1) |

## Not Working via DDC/CI

| Feature | Notes |
|---------|-------|
| PIP (Picture-in-Picture) | 0xD7=0x00 shows in menu but doesn't activate. Requires USB HID. |
| PIP position/size | Not exposed via any VCP code |
| PBP input swap | Not found |
| Standard input (0x60) | Monitor ignores writes, only reads work |

## VCP Codes Reference

### Feature 0xF4 (Input - LG proprietary, address 0x50)
- `0xD0` = DisplayPort 1
- `0xD1` = DisplayPort 2 / USB-C (depending on monitor)
- `0xD2` = DisplayPort 3 / USB-C
- `0x90` = HDMI 1
- `0x91` = HDMI 2
- `0x00` = Auto

### Feature 0xD7 (PBP/Split mode)
- `0x00` = PIP mode (cannot be set via DDC)
- `0x01` = Off (single input)
- `0x03` = 66/33 split (not on all monitors)
- `0x05` = 50/50 split

### Feature 0xAF
This is a **counter** that increments on each read. Not useful for control.

## NixOS Configuration

See `kvm-switch.nix` for automatic input switching based on USB hub detection.

Requirements in NixOS config:
```nix
hardware.i2c.enable = true;  # Enables i2c-dev module and udev rules
environment.systemPackages = [ pkgs.ddcutil ];
users.users.yourname.extraGroups = [ "i2c" ];
```

## Resources

- https://github.com/rockowitz/ddcutil/wiki/Switching-input-source-on-LG-monitors
- https://github.com/shinyquagsire23/lg_display_manager
