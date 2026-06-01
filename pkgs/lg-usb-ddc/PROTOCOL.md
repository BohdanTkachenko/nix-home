# RealSil "iUSB2I2C" USB-HID -> I2C/DDC bridge protocol

Reverse-engineered from LG Switch.app's `iUSB2I2C.framework` (macOS universal Mach-O,
unstripped). All offsets below are arm64 vaddrs in the carved thin slice `/tmp/iusb_arm64`
(fat arm64 was at fat file offset `0x28000`). The x86_64 slice (fat offset `0x4000`) was
spot-checked and produces byte-identical report framing.

The bridge is a Realtek RTS5411 USB hub that exposes a vendor HID interface. The framework
tunnels generic I2C read/write transactions over HID reports. LG layers DDC/CI on top of
that generic I2C transport; the framework itself contains **no** DDC/VCP knowledge (no
"VCP"/"DDC"/"0x60" strings in `iUSB2I2C`), so the DDC frame is built by the caller and the
spec below covers (a) the byte-exact HID transport and (b) how LG Switch's main binary
drives it for a DDC transaction.

---

## 1. HID transport: setReport / getReport

All "out" pipe functions converge on the same code shape. Verified in `_HID_CtlPipeOut`
(`0x9d38`), `_HID_CtrlPipeOut` (`0xb920`), `_HID_VdCmdEnable` (`0x7804`),
`_HID_CtlPipeNoDataOut` (`0xa0c8`). They all:

1. Take an **8-byte command header** (pointer in `x0`) plus an optional data pointer (`x1`).
2. `memset` a fixed **0xC0 = 192-byte** scratch buffer to 0.
3. Copy the 8-byte header to **offset 0** of that buffer.
4. (write path only) `__memcpy_chk(dst = buf + 0x40, src = dataPtr, n = len, max = 0x80)`
   — i.e. the **I2C data payload is placed at buffer offset 0x40**, capped at 0x80 bytes.
5. Call the IOHIDDeviceInterface function pointer at **vtable + 0x68 = `setReport`**.

The `setReport` call (disasm `_HID_CtlPipeOut` @ `0x9ea0`-`0x9ecc`):

```
0x9e98  ldr  x9, [x9, 0x68]      ; x9 = (*IOHIDDeviceInterface)->setReport   (vtable+0x68)
0x9ea0  mov  x0, x8              ; arg0 = g_HIDDev  (the IOHIDDeviceInterface**)
0x9ea4  mov  w1, 1              ; arg1 = IOHIDReportType = 1 = kIOHIDReportTypeOutput
0x9ea8  ldr  w2, [arg_70hx14]   ; arg2 = reportID = 0          (set from w11=0 @ 0x9e3c)
0x9eac  ldr  x3, [arg_70hx20]   ; arg3 = report buffer pointer (the 0xC0 buffer, header @0)
0x9eb0  ldr  x4, [var_0h_19]    ; arg4 = reportLength = 0xC0 = 192   (set from x10=0xC0)
0x9eb4  mov  w5, 0x7d0          ; arg5 = timeoutMs = 2000
        ... x6=x7=NULL (callback/target), *sp = 0 (refcon)
0x9ecc  blr  x9
```

**Transport summary**

| field         | value                                              |
| ------------- | -------------------------------------------------- |
| report TYPE   | **Output** (`kIOHIDReportTypeOutput`, w1 = 1)      |
| report ID     | **0** (no leading report-ID byte)                  |
| report length | **192 (0xC0)** bytes, zero-padded                  |
| layout        | bytes [0..8) = command header; bytes [0x40..) = I2C data payload |
| timeout       | 2000 ms                                            |

On Linux/hidapi this is `hid_write(dev, buf, 192)` where `buf[0]` is the report-ID byte.
Because the macOS report ID is **0**, on Linux we must **prepend a `0x00` report-ID byte**
to the hidapi buffer (hidapi always treats buf[0] as the report ID). So the hidapi write
buffer is **193 bytes**: `[0x00] + [192-byte report]`. See the "uncertainties" section.

The READ/getReport path (`_RtHIDDataIn` @ `0x7924`) first does a `setReport`
(vtable+0x68, type=Output, id=1, len=0xC0) to push the read-request command, then a
`getReport` at **vtable + 0x70** (type=Output(!) id=0, into a 0x100 buffer, len 0xC0) and
copies the requested number of bytes back to the caller.

---

## 2. Command header (8 bytes) — all opcodes share this shape

Every operation builds an 8-byte little-endian header. Byte 0 is the RealSil vendor marker
/ direction flag, byte 1 is the opcode, bytes 2-5 are a 32-bit LE argument, bytes 6-7 are a
16-bit LE length. The exact meaning of bytes 2-7 depends on the opcode.

| op             | byte0 | byte1 (opcode) | bytes 2-5 (LE32)         | bytes 6-7 (LE16) | data@0x40 |
| -------------- | ----- | -------------- | ----------------------- | ---------------- | --------- |
| Vendor enable  | 0x40  | 0x02           | VID (LE16) in b2,b3; b4,b5 = 0xDA,0x0B | 0x0000 | none |
| Config addr    | 0x40  | 0xF6           | b2=value, b3=addr, b4=0x80\|(speed&7), b5=0x80 | 0x0000 | none |
| I2C write      | 0x40  | 0xC6           | slaveAddr (LE32)         | data length      | yes (len) |
| I2C read       | 0xC0  | 0xD6           | slaveAddr (LE32)         | read length      | none (req)|

Note byte0 differs: **0x40 for writes / config / enable, 0xC0 for reads**. The high bit of
byte0 appears to encode "device->host data phase follows".

---

## 3. Vendor-enable handshake — REQUIRED before any I2C op

`-[CRtsHub RsVendorCmdEnbale:]` (`0xdd70`) -> `_HID_VdCmdEnable` (`0x7804`).
The C export `_VendorCmdEnable(vid)` (`0xb1c8`) -> `[g_hub RsVendorCmdEnbale: vid]`.

`_HID_VdCmdEnable` builds this 8-byte header (disasm `0x7830`-`0x7874`):

```
byte0 = 0x40              ; 0x7830 mov w10,0x40
byte1 = 0x02              ; 0x7838 mov w10,2          (vendor-enable opcode)
byte2 = vid & 0xff        ; 0x7844 (arg1 low)
byte3 = (vid >> 8) & 0xff ; 0x7850 (arg1 high)
byte4 = 0xDA              ; 0x785c mov w10,0xDA       ; Realtek VID 0x0BDA, LE
byte5 = 0x0B              ; 0x7864 mov w10,0x0B
byte6 = 0x00
byte7 = 0x00
```

LG passes **vid = 1** (`mov w8,1; strh; ldrsh w0` at `0x1001716f8`-`0x100171700` in the main
binary), NOT 0x0BDA. So the on-wire enable report header is:

```
40 02 01 00 DA 0B 00 00            ; (then padded to 192 bytes)
```

`0xDA 0x0B` (the literal Realtek VID, LE) is hard-coded in bytes 4-5; bytes 2-3 carry the
"1" LG passes. Treat bytes 2-3 as a magic constant `0x0001` matching LG's behaviour.

---

## 4. Config-address — programs the I2C target + bus speed

`-[CRtsHub USB2I2C_ConfigAddr:andValue:andSpeed:]` (`0xd9c4`). C export `_SetBusSpeed(addr,
value, speed)` (`0xae84`) -> `[g_hub USB2I2C_ConfigAddr: addr andValue: value andSpeed:
speed]`.

Header built (disasm `0xda24`-`0xda5c`), opcode **0xF6**:

```
byte0 = 0x40
byte1 = 0xF6
byte2 = value                 ; 0xda34 from arg4 (andValue:)
byte3 = addr                  ; 0xda3c from arg3 (the I2C target address, ConfigAddr:)
byte4 = 0x80 | (speed & 7)    ; 0xda0c-0xda1c: (speed & 7) OR 0x80
byte5 = 0x80                  ; 0xda4c mov w8,0x80
byte6 = 0x00
byte7 = 0x00
```

Sent with **no** data payload via `_HID_CtlPipeNoDataOut` (`0xa0c8`).

LG's call (main binary `0x100171708`-`0x100171718`):

```
mov w0, 0x6e   ; addr  = 0x6E   (8-bit I2C write address of the DDC/CI display)
mov w2, 1      ; speed = 1
mov x1, x2 -> w1 = 1 ; value = 1
bl SetBusSpeed ; => USB2I2C_ConfigAddr: 0x6E andValue: 1 andSpeed: 1
```

So the on-wire config report header is:

```
40 F6 01 6E 81 80 00 00            ; value=1, addr=0x6E, speed-byte=0x81 (0x80|1), 0x80
```

**This programs the bridge's I2C target address to 0x6E** (the display) and speed code 1.
It is sent **once per transaction**, right after vendor-enable and before the I2C write.

---

## 5. I2C write — `-[CRtsHub USB2I2C_Write:::]` (`0xdae0`)

C export `_WriteI2C(slaveAddr, dataPtr, len)` (`0xb0fc`) ->
`[g_hub USB2I2C_Write: slaveAddr : dataPtr : len]`. Args: `w2 = slaveAddr`, `x3 = dataPtr`,
`w4 = len`.

Header built (disasm `0xdb30`-`0xdb84`), opcode **0xC6**:

```
byte0 = 0x40                       ; 0xdb30 mov w9,0x40
byte1 = 0xC6                       ; 0xdb38 mov w9,0xC6      (I2C-write opcode)
byte2 = slaveAddr        & 0xff    ; 0xdb40
byte3 = (slaveAddr >> 8) & 0xff    ; 0xdb50
byte4 = (slaveAddr >> 16)& 0xff    ; 0xdb5c
byte5 = (slaveAddr >> 24)& 0xff    ; 0xdb68
byte6 =  len             & 0xff    ; 0xdb74
byte7 = (len >> 8)       & 0xff    ; 0xdb7c
```

then `_HID_CtlPipeOut(header, dataPtr)` copies `len` payload bytes to **report offset
0x40**. `_MP_I2C_Write` (`0xbe18`) builds a byte-identical header (verified) confirming the
field layout.

### What LG actually puts on the wire (DDC GetVCP example)

The main binary at `0x100171624`-`0x100171758` builds the I2C payload and calls WriteI2C:

```
ldr  w8, [0x10054f030] ; w8 = first 4 bytes of a DDC template = 82 01 EF 53
str  w8, [sp, 0x8c]    ; payload[0..4) = 82 01 EF 53
mov  w8, 0x3f          ; checksum seed = 0x3F  (== 0x6E ^ 0x51)
strb w8, [sp, 0x8b]
; loop i in 0..3: checksum ^= payload[i]   (XOR of the 3 message bytes 82,01,EF)
strb checksum, [sp, 0x8f] ; payload[3] = checksum  => 82 01 EF 53
...
mov  w0, 0x51          ; slaveAddr arg = 0x51   <-- the DDC SOURCE address
add  x1, sp, 0x8c      ; dataPtr  = payload
mov  w2, 4             ; len = 4
bl   WriteI2C          ; => USB2I2C_Write: 0x51 : payload : 4
```

Key deductions:

* **ConfigAddr set the I2C device address to 0x6E** (the display's 8-bit write address).
  The bridge drives the I2C START + 0x6E on the bus.
* The `slaveAddr` arg to `WriteI2C` is **0x51**, the **DDC/CI source/host address**, which
  becomes the **first byte written on the wire** after the I2C address. (It is NOT the I2C
  bus address — that came from ConfigAddr.)
* The 4-byte payload is the DDC message body: `[0x80|len, opcode, data..., checksum]`. For
  this probe: `0x82` (= 0x80|2, length 2), `0x01` (GetVCP feature opcode), `0xEF` (VCP code),
  `0x53` (checksum).
* **Checksum** = XOR of every byte the display sees, seeded with `0x6E ^ 0x51 = 0x3F`:
  `chk = 0x6E ^ 0x51 ^ 0x82 ^ 0x01 ^ 0xEF = 0x53`. This is the textbook DDC/CI checksum
  (dest-addr XOR source-addr XOR message-bytes).

So the complete on-wire DDC frame to the display is:
`<I2C addr 0x6E> 0x51 0x82 0x01 0xEF 0x53`.

### Generalised to **Set VCP 0x60 = VV** (input source)

A DDC `Set VCP feature` message body is: `0x84 0x03 <vcp> <hi> <lo>` where `0x84 = 0x80|4`.
For VCP 0x60 (input source), `<vcp>=0x60`, `<hi>=0x00`, `<lo>=VV`. So:

* WriteI2C slaveAddr arg = **0x51** (DDC source; configurable `--source-addr`).
* payload (len = 6) = `[0x84, 0x03, 0x60, 0x00, VV, chk]`
  where `chk = 0x6E ^ 0x51 ^ 0x84 ^ 0x03 ^ 0x60 ^ 0x00 ^ VV`.
* ConfigAddr must have set addr = 0x6E first.

> The task brief's frame `[source, 0x84, 0x03, 0x60, 0x00, VV, chk]` puts the source byte
> *inside* the payload. The disasm shows LG instead passes the source as the WriteI2C
> *slaveAddr* arg and leaves it out of the payload. Both produce the same bytes on the wire
> only if the firmware prepends the slaveAddr arg as the first wire byte. **This is the #1
> thing to validate on hardware** — the tool supports both framings via `--source-in-payload`.

---

## 6. I2C read — `-[CRtsHub USB2I2C_Read:::]` (`0xdc28`) / `_HID_CtlPipeIn` (`0x9f34`)

C export `_ReadI2C(slaveAddr, dataPtr, len)` (`0xb028`).

Header built (disasm `0xdc78`-`0xdccc`), opcode **0xD6**, byte0 = **0xC0**:

```
byte0 = 0xC0
byte1 = 0xD6
byte2..5 = slaveAddr (LE32)
byte6..7 = read length (LE16)
```

`_HID_CtlPipeIn` sends this request header via getReport plumbing and then calls
`_RtHIDDataIn(dst, readLen)` which performs setReport(req) + getReport(vtable+0x70) and
copies `readLen` bytes back.

LG's read (main binary `0x100171778`-`0x100171788`): after the WriteI2C it does
`usleep(0x186A0 = 100000 = 100 ms)`, then `ReadI2C(slave = 0x51, dst = x29-0x78, len = 0xB)`
(11 bytes). The 11-byte reply is the DDC/CI GetVCP response:
`0x6F 0x88 0x02 <result> <vcp> <type> <maxhi> <maxlo> <curhi> <curlo> <chk>` — i.e. for a
VCP query you parse the "current value" at reply offset 8-9 (`<curhi> <curlo>`).

To verify an input switch over USB: GetVCP 0x60 = WriteI2C(slave=0x51, `[0x82, 0x01, 0x60,
chk]`, 4) -> usleep(100ms) -> ReadI2C(slave=0x51, 11) and read the current value at reply[9].

---

## 7. Exact call order LG uses for one DDC transaction

From `fcn.100171704` in the main binary (the GetVCP path; SetVCP is the same sans the read):

```
OpenDevice / RetrieveDeviceInfo      ; (done once; opens the matched IOHIDDevice)
VendorCmdEnable(1)                    ; report: 40 02 01 00 DA 0B 00 00
SetBusSpeed(addr=0x6E, value=1, speed=1)   ; report: 40 F6 01 6E 81 80 00 00
WriteI2C(slave=0x51, payload, len)   ; report: 40 C6 51 00 00 00 <len> 00  + payload@0x40
usleep(100000)                       ; 100 ms   (only needed before a read)
ReadI2C(slave=0x51, len=0x0B)        ; report: C0 D6 51 00 00 00 0B 00     (verification)
CloseDevice / Deinit
```

For a pure **input switch** (no read-back) the minimal sequence is:

```
VendorCmdEnable(1)
SetBusSpeed(0x6E, 1, 1)
WriteI2C(0x51, [0x84,0x03,0x60,0x00,VV,chk], 6)
```

---

## 8. Per-input VCP 0x60 values

LG "alt"/manufacturer values (from the brief; LG UltraGear uses these):

| input | alt value | standard MCCS value |
| ----- | --------- | ------------------- |
| dp1   | 0xD0      | 0x0F                |
| dp2   | 0xD1      | 0x10                |
| hdmi1 | 0x90      | 0x11                |
| hdmi2 | 0x91      | 0x12                |
| usbc  | 0xD2      | (no std; reuse 0xD2)|

---

## 9. Assumptions & uncertainties to validate on hardware

1. **Report-ID byte on Linux.** macOS uses reportID 0. hidapi always consumes `buf[0]` as
   the report ID, so the tool sends a 193-byte buffer = `0x00` + 192. If the device's HID
   descriptor declares a non-zero report ID for the output report, change `REPORT_ID`. The
   true descriptor can be dumped with `lg-usb-ddc list --verbose` (it prints the report
   descriptor length) or `usbhid-dump` / parsing `/sys/.../report_descriptor`.

2. **Report length 192.** macOS sends a fixed 192-byte output report. If `hid_write`
   returns -1 / EPIPE, the Linux HID output report may be a different size; try the natural
   report length from the descriptor. Tunable via `--report-len`.

3. **Source-address framing (most important).** LG passes the DDC source (0x51) as the
   WriteI2C *slaveAddr* arg and omits it from the payload, relying on the firmware to
   prepend it. The tool defaults to this (`slaveAddr = source`, payload = message body
   only). `--source-in-payload` instead passes `slaveAddr = 0x6E` and prepends the source
   byte into the payload, in case the firmware writes the slaveAddr arg verbatim as the I2C
   bus address. Try the default first; if the monitor ignores it, try the alternative.

4. **ConfigAddr `value`/`speed` constants.** LG uses value=1, speed=1. byte4 = 0x80|(speed&7)
   = 0x81. These are exposed via `--config-value` / `--config-speed` but default to LG's.

5. **0x6E vs 0x37.** 0x6E is the 8-bit write address (0x37 << 1). ConfigAddr is given 0x6E
   directly. If the firmware expects the 7-bit address, pass `--ddc-addr 0x37`.

6. **Which VCP-0x60 value set the panel honours** (alt vs standard) is model-dependent;
   `--standard` selects the MCCS table. The 45GX950A is reported to need the alt values.

7. **VCP feature 0x60 vs 0xF4 (important).** The brief targets VCP `0x60` (standard MCCS
   "Input Select"). However the user's existing `nixos/hardware/kvm-switch.nix` switched this
   exact monitor with `ddcutil setvcp 0xF4 0xD0 --i2c-source-addr=0x50` — i.e. LG UltraGear+
   uses the **non-standard feature 0xF4** (and source address 0x50) for input switching, with
   the same input value table (0xD0=DP1, 0xD1=USB-C, 0x90=HDMI1, 0x91=HDMI2). The framework
   itself is feature-agnostic; the tool defaults to 0x60 but exposes `--vcp 0xf4`. **Try
   `--vcp 0xf4` first** for this panel, since that is the feature the working ddcutil path
   used. The whole point of the USB bridge is that the panel ignores these writes over the
   *cable* DDC but honours them over the *USB hub* I2C path.
