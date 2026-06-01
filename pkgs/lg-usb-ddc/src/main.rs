//! lg-usb-ddc
//!
//! Drive an LG monitor's DDC/CI over a RealSil RTS5411 USB-HID I2C bridge, replicating
//! LG Switch.app's `iUSB2I2C.framework`. The 45GX950A ignores input-source switching over
//! the cable DDC channel but obeys it through this USB bridge.
//!
//! Protocol (see PROTOCOL.md for byte-exact disasm citations):
//!   * Transport = HID OUTPUT report, report-id 0, fixed 192-byte payload.
//!       - bytes [0..8)   = 8-byte command header (LE)
//!       - bytes [0x40..) = I2C data payload (write path only)
//!   * On Linux/hidapi we prepend a 0x00 report-id byte => 193-byte hid_write buffer.
//!   * Sequence for a transaction: VendorCmdEnable(1) -> ConfigAddr(0x6E,1,1) -> WriteI2C.
//!
//! Header opcodes:
//!   vendor-enable  byte0=0x40 byte1=0x02  b2,b3=0x0001  b4,b5=0xDA,0x0B
//!   config-addr    byte0=0x40 byte1=0xF6  b2=value b3=addr b4=0x80|(speed&7) b5=0x80
//!   i2c-write      byte0=0x40 byte1=0xC6  b2..5=slaveAddr(LE32) b6..7=len(LE16) data@0x40
//!   i2c-read       byte0=0xC0 byte1=0xD6  b2..5=slaveAddr(LE32) b6..7=len(LE16)

use std::process::ExitCode;

use hidapi::{HidApi, HidDevice};

// ---- constants from the disassembly ---------------------------------------------------

const REALTEK_VID: u16 = 0x0BDA;

/// macOS report id is 0; hidapi consumes buf[0] as the report id, so we prepend it.
const REPORT_ID: u8 = 0x00;
/// macOS sends a fixed 0xC0-byte output report.
const REPORT_LEN: usize = 0xC0; // 192
/// I2C data payload is copied to this offset inside the report (memcpy dst = buf + 0x40).
const PAYLOAD_OFFSET: usize = 0x40;

// command header opcodes (header byte1) and direction markers (header byte0)
const MARK_OUT: u8 = 0x40;
const MARK_IN: u8 = 0xC0;
const OP_VENDOR_ENABLE: u8 = 0x02;
const OP_CONFIG_ADDR: u8 = 0xF6;
const OP_I2C_WRITE: u8 = 0xC6;
const OP_I2C_READ: u8 = 0xD6;

// vendor-enable magic (LG passes vid=1; bytes 4,5 = literal Realtek VID 0x0BDA LE)
const VENDOR_ENABLE_ARG: u16 = 0x0001;

// DDC defaults
const DDC_ADDR_8BIT: u8 = 0x6E; // monitor I2C write address (programmed via ConfigAddr)
const DDC_SOURCE_DEFAULT: u8 = 0x50; // LG host source byte; LG Switch used 0x51 in probes
const VCP_INPUT_SELECT: u8 = 0x60;

// ConfigAddr defaults (LG: value=1, speed=1)
const CONFIG_VALUE_DEFAULT: u8 = 0x01;
const CONFIG_SPEED_DEFAULT: u8 = 0x01;

const READ_SETTLE_US: u64 = 100_000; // LG usleep(0x186A0) before a read-back

// ---- input value tables ----------------------------------------------------------------

/// LG "alt"/manufacturer VCP-0x60 values (UltraGear). Returns None if not a known name.
fn input_value_alt(name: &str) -> Option<u8> {
    Some(match name {
        "dp1" => 0xD0,
        "dp2" => 0xD1,
        "hdmi1" => 0x90,
        "hdmi2" => 0x91,
        "usbc" => 0xD2,
        _ => return None,
    })
}

/// Standard MCCS VCP-0x60 values.
fn input_value_standard(name: &str) -> Option<u8> {
    Some(match name {
        "dp1" => 0x0F,
        "dp2" => 0x10,
        "hdmi1" => 0x11,
        "hdmi2" => 0x12,
        "usbc" => 0xD2, // no standard code for USB-C alt mode; reuse alt
        _ => return None,
    })
}

// ---- CLI options -----------------------------------------------------------------------

struct Opts {
    device: Option<String>,
    pid: Option<u16>,
    source_addr: u8,
    ddc_addr: u8,
    config_value: u8,
    config_speed: u8,
    report_len: usize,
    report_id: u8,
    source_in_payload: bool,
    standard: bool,
    vcp: u8,
    verbose: bool,
}

impl Default for Opts {
    fn default() -> Self {
        Opts {
            device: None,
            pid: None,
            source_addr: DDC_SOURCE_DEFAULT,
            ddc_addr: DDC_ADDR_8BIT,
            config_value: CONFIG_VALUE_DEFAULT,
            config_speed: CONFIG_SPEED_DEFAULT,
            report_len: REPORT_LEN,
            report_id: REPORT_ID,
            source_in_payload: false,
            standard: false,
            vcp: VCP_INPUT_SELECT,
            verbose: false,
        }
    }
}

fn parse_int(s: &str) -> Result<u32, String> {
    let s = s.trim();
    let v = if let Some(h) = s.strip_prefix("0x").or_else(|| s.strip_prefix("0X")) {
        u32::from_str_radix(h, 16)
    } else {
        s.parse::<u32>()
    };
    v.map_err(|_| format!("invalid number: {s:?}"))
}

// ---- report construction ---------------------------------------------------------------

/// Build the 8-byte command header.
fn header(byte0: u8, op: u8, arg32: u32, len16: u16) -> [u8; 8] {
    let a = arg32.to_le_bytes();
    let l = len16.to_le_bytes();
    [byte0, op, a[0], a[1], a[2], a[3], l[0], l[1]]
}

/// Assemble the full hidapi write buffer: [report_id] + 192-byte report
/// (header @0, optional data @0x40).
fn build_report(opts: &Opts, hdr: &[u8; 8], payload: &[u8]) -> Vec<u8> {
    let mut buf = vec![0u8; 1 + opts.report_len];
    buf[0] = opts.report_id;
    buf[1..1 + 8].copy_from_slice(hdr);
    if !payload.is_empty() {
        let off = 1 + PAYLOAD_OFFSET;
        let n = payload.len().min(0x80).min(opts.report_len - PAYLOAD_OFFSET);
        buf[off..off + n].copy_from_slice(&payload[..n]);
    }
    buf
}

fn hexdump(label: &str, data: &[u8]) {
    eprint!("{label} ({} bytes):", data.len());
    for (i, b) in data.iter().enumerate() {
        if i % 16 == 0 {
            eprint!("\n  {i:04x}:");
        }
        eprint!(" {b:02x}");
    }
    eprintln!();
}

fn write_report(dev: &HidDevice, opts: &Opts, buf: &[u8], what: &str) -> Result<(), String> {
    if opts.verbose {
        hexdump(&format!("[TX {what}]"), buf);
    }
    dev.write(buf).map_err(|e| format!("hid_write failed ({what}): {e}"))?;
    Ok(())
}

// ---- high-level operations -------------------------------------------------------------

fn vendor_enable(dev: &HidDevice, opts: &Opts) -> Result<(), String> {
    // header: 40 02 <vid_lo> <vid_hi> DA 0B 00 00
    let mut hdr = header(MARK_OUT, OP_VENDOR_ENABLE, VENDOR_ENABLE_ARG as u32, 0);
    hdr[4] = (REALTEK_VID & 0xFF) as u8; // 0xDA
    hdr[5] = (REALTEK_VID >> 8) as u8; // 0x0B
    let buf = build_report(opts, &hdr, &[]);
    write_report(dev, opts, &buf, "vendor-enable")
}

fn config_addr(dev: &HidDevice, opts: &Opts) -> Result<(), String> {
    // header: 40 F6 <value> <addr> (0x80|(speed&7)) 0x80 00 00
    let mut hdr = [0u8; 8];
    hdr[0] = MARK_OUT;
    hdr[1] = OP_CONFIG_ADDR;
    hdr[2] = opts.config_value;
    hdr[3] = opts.ddc_addr;
    hdr[4] = 0x80 | (opts.config_speed & 0x07);
    hdr[5] = 0x80;
    let buf = build_report(opts, &hdr, &[]);
    write_report(dev, opts, &buf, "config-addr")
}

/// Low-level I2C write through the bridge. `slave` goes in header bytes 2-5,
/// `payload` is copied to report offset 0x40.
fn i2c_write(dev: &HidDevice, opts: &Opts, slave: u8, payload: &[u8]) -> Result<(), String> {
    let hdr = header(MARK_OUT, OP_I2C_WRITE, slave as u32, payload.len() as u16);
    let buf = build_report(opts, &hdr, payload);
    write_report(dev, opts, &buf, "i2c-write")
}

/// Low-level I2C read request. Sends the read header then reads back `len` bytes.
fn i2c_read(dev: &HidDevice, opts: &Opts, slave: u8, len: u16) -> Result<Vec<u8>, String> {
    let hdr = header(MARK_IN, OP_I2C_READ, slave as u32, len);
    let buf = build_report(opts, &hdr, &[]);
    write_report(dev, opts, &buf, "i2c-read-req")?;

    // Read the input report back. hidapi returns the report (without the report-id byte
    // when the device uses numbered reports; with it otherwise). We over-allocate.
    let mut rx = vec![0u8; opts.report_len + 1];
    let n = dev
        .read_timeout(&mut rx, 2000)
        .map_err(|e| format!("hid_read failed: {e}"))?;
    rx.truncate(n);
    if opts.verbose {
        hexdump("[RX i2c-read]", &rx);
    }
    Ok(rx)
}

/// DDC checksum: XOR of (dest 8-bit addr) ^ (source addr) ^ message bytes.
fn ddc_checksum(dest: u8, source: u8, msg: &[u8]) -> u8 {
    let mut c = dest ^ source;
    for &b in msg {
        c ^= b;
    }
    c
}

/// Perform one DDC write, choosing the slave/payload framing per `source_in_payload`.
fn ddc_write(dev: &HidDevice, opts: &Opts, msg: &[u8]) -> Result<(), String> {
    vendor_enable(dev, opts)?;
    config_addr(dev, opts)?;

    let chk = ddc_checksum(opts.ddc_addr, opts.source_addr, msg);
    if opts.source_in_payload {
        // alt framing: slave = 0x6E, payload = [source, msg..., chk]
        let mut payload = Vec::with_capacity(2 + msg.len());
        payload.push(opts.source_addr);
        payload.extend_from_slice(msg);
        payload.push(chk);
        if opts.verbose {
            hexdump("[DDC frame (slave=ddc_addr)]", &payload);
        }
        i2c_write(dev, opts, opts.ddc_addr, &payload)
    } else {
        // LG framing: slave = source addr, payload = [msg..., chk]
        let mut payload = Vec::with_capacity(1 + msg.len());
        payload.extend_from_slice(msg);
        payload.push(chk);
        if opts.verbose {
            hexdump(
                &format!("[DDC frame (slave=0x{:02x} source)]", opts.source_addr),
                &payload,
            );
        }
        i2c_write(dev, opts, opts.source_addr, &payload)
    }
}

// ---- device selection ------------------------------------------------------------------

fn open_device(api: &HidApi, opts: &Opts) -> Result<HidDevice, String> {
    if let Some(path) = &opts.device {
        let cpath = std::ffi::CString::new(path.as_str()).map_err(|e| e.to_string())?;
        return api
            .open_path(&cpath)
            .map_err(|e| format!("cannot open {path}: {e}"));
    }

    // auto-pick: first Realtek device (optionally matching --pid)
    let mut candidate: Option<&hidapi::DeviceInfo> = None;
    for d in api.device_list() {
        if d.vendor_id() != REALTEK_VID {
            continue;
        }
        if let Some(pid) = opts.pid {
            if d.product_id() != pid {
                continue;
            }
        }
        candidate = Some(d);
        break;
    }
    let d = candidate.ok_or_else(|| {
        "no Realtek (0x0bda) HID device found; run `lg-usb-ddc list` and pass --device".to_string()
    })?;
    if opts.verbose {
        eprintln!(
            "[auto] opening {:04x}:{:04x} path={:?} iface={}",
            d.vendor_id(),
            d.product_id(),
            d.path(),
            d.interface_number()
        );
    }
    d.open_device(api).map_err(|e| format!("open failed: {e}"))
}

// ---- subcommands -----------------------------------------------------------------------

fn cmd_list(api: &HidApi) -> Result<(), String> {
    let mut found = false;
    for d in api.device_list() {
        if d.vendor_id() != REALTEK_VID {
            continue;
        }
        found = true;
        println!(
            "{:04x}:{:04x}  iface={:<3} usage_page=0x{:04x} usage=0x{:04x}  product={:?}  path={:?}",
            d.vendor_id(),
            d.product_id(),
            d.interface_number(),
            d.usage_page(),
            d.usage(),
            d.product_string().unwrap_or("?"),
            d.path(),
        );
    }
    if !found {
        println!("(no HID devices with vendor_id 0x0bda found)");
    }
    Ok(())
}

fn cmd_switch(api: &HidApi, opts: &Opts, input: &str) -> Result<(), String> {
    let value = if let Some(v) = (if opts.standard {
        input_value_standard
    } else {
        input_value_alt
    })(input)
    {
        v
    } else {
        // raw hex/decimal value
        let n = parse_int(input)?;
        if n > 0xFF {
            return Err(format!("input value 0x{n:x} does not fit in one byte"));
        }
        n as u8
    };

    eprintln!(
        "switching input -> {input} (VCP 0x{:02x} = 0x{:02x}{})",
        opts.vcp,
        value,
        if opts.standard { ", standard" } else { ", alt" }
    );

    // DDC SetVCP body: 0x84 0x03 <vcp> 0x00 <value>  (0x84 = 0x80|4)
    let msg = [0x84u8, 0x03, opts.vcp, 0x00, value];
    let dev = open_device(api, opts)?;
    ddc_write(&dev, opts, &msg)?;
    eprintln!("done");
    Ok(())
}

fn cmd_raw_i2c(api: &HidApi, opts: &Opts, slave: u8, data: &[u8]) -> Result<(), String> {
    let dev = open_device(api, opts)?;
    vendor_enable(&dev, opts)?;
    config_addr(&dev, opts)?;
    i2c_write(&dev, opts, slave, data)?;
    eprintln!("sent {} byte(s) to I2C slave 0x{:02x}", data.len(), slave);
    Ok(())
}

fn cmd_getvcp(api: &HidApi, opts: &Opts, code: u8) -> Result<(), String> {
    let dev = open_device(api, opts)?;
    vendor_enable(&dev, opts)?;
    config_addr(&dev, opts)?;

    // DDC GetVCP body: 0x82 0x01 <vcp>  (0x82 = 0x80|2)
    let msg = [0x82u8, 0x01, code];
    let chk = ddc_checksum(opts.ddc_addr, opts.source_addr, &msg);

    if opts.source_in_payload {
        let mut p = vec![opts.source_addr];
        p.extend_from_slice(&msg);
        p.push(chk);
        i2c_write(&dev, opts, opts.ddc_addr, &p)?;
    } else {
        let mut p = msg.to_vec();
        p.push(chk);
        i2c_write(&dev, opts, opts.source_addr, &p)?;
    }

    std::thread::sleep(std::time::Duration::from_micros(READ_SETTLE_US));

    // GetVCP reply is 11 bytes: 6F 88 02 <res> <vcp> <type> <maxhi> <maxlo> <curhi> <curlo> <chk>
    let reply = i2c_read(&dev, opts, opts.source_addr, 0x0B)?;
    hexdump("getvcp reply", &reply);

    // Try to locate the DDC reply within the returned bytes. The framework copies the I2C
    // data back; depending on framing the reply body may start at index 0 or after a header.
    if let Some(pos) = reply.iter().position(|&b| b == 0x88) {
        let body = &reply[pos.saturating_sub(1)..];
        if body.len() >= 10 {
            let cur = ((body[8] as u16) << 8) | body[9] as u16;
            println!(
                "VCP 0x{code:02x} current = 0x{cur:04x} ({cur})  [vcp-echo=0x{:02x}]",
                body.get(4).copied().unwrap_or(0)
            );
            return Ok(());
        }
    }
    println!("could not parse GetVCP reply; inspect the hexdump above (use --verbose)");
    Ok(())
}

// ---- arg parsing & main ----------------------------------------------------------------

fn usage() -> &'static str {
    "lg-usb-ddc - DDC/CI over RealSil RTS5411 USB-HID bridge

USAGE:
  lg-usb-ddc [GLOBAL FLAGS] <COMMAND> [ARGS]

COMMANDS:
  list                         enumerate HID devices with vendor_id 0x0bda
  switch <input>               set VCP 0x60 input source. <input> is one of
                               dp1 dp2 hdmi1 hdmi2 usbc, or a raw hex/decimal byte
  raw-i2c --slave 0x6e --data \"50 84 03 60 00 d0 ..\"
                               send arbitrary bytes through the bridge to an I2C slave
  getvcp <code>                read a VCP code (hex/decimal) for verification

GLOBAL FLAGS:
  --device <path>              hidraw path / open path (override auto-pick)
  --pid <hex>                  restrict auto-pick to this product id
  --source-addr 0x50|0x51      DDC source byte (default 0x50; LG Switch used 0x51)
  --vcp 0x60|0xf4              VCP feature for `switch` (default 0x60; LG UltraGear+ uses
                               the non-standard 0xF4 over the cable - try both)
  --ddc-addr 0x6e              monitor I2C address programmed via ConfigAddr (default 0x6e)
  --config-value <n>           ConfigAddr 'value' byte (default 1)
  --config-speed <n>           ConfigAddr bus-speed code, 0..7 (default 1)
  --report-len <n>             output report length (default 192)
  --report-id <n>              HID report id byte (default 0)
  --source-in-payload          put the source byte in the payload and use ddc-addr as the
                               I2C slave, instead of LG's framing (slave = source). Try this
                               if the default framing does not switch the panel.
  --standard                   use standard MCCS VCP-0x60 values instead of LG alt values
  --verbose                    hexdump every report sent/received

EXAMPLES:
  lg-usb-ddc list
  lg-usb-ddc switch dp1
  lg-usb-ddc --verbose switch hdmi2
  lg-usb-ddc raw-i2c --slave 0x51 --data \"84 03 60 00 d0\"
  lg-usb-ddc getvcp 0x60
"
}

fn run() -> Result<(), String> {
    let args: Vec<String> = std::env::args().skip(1).collect();
    let mut opts = Opts::default();

    // pull global flags out of the arg vector
    let mut i = 0;
    let mut positional: Vec<String> = Vec::new();
    let mut raw_slave: Option<u8> = None;
    let mut raw_data: Option<String> = None;

    while i < args.len() {
        let a = args[i].clone();
        let take_val = |i: &mut usize| -> Result<String, String> {
            *i += 1;
            args.get(*i)
                .cloned()
                .ok_or_else(|| format!("flag {a} needs a value"))
        };
        match a.as_str() {
            "-h" | "--help" => {
                print!("{}", usage());
                return Ok(());
            }
            "--verbose" | "-v" => opts.verbose = true,
            "--standard" => opts.standard = true,
            "--source-in-payload" => opts.source_in_payload = true,
            "--vcp" => opts.vcp = parse_int(&take_val(&mut i)?)? as u8,
            "--device" => opts.device = Some(take_val(&mut i)?),
            "--pid" => opts.pid = Some(parse_int(&take_val(&mut i)?)? as u16),
            "--source-addr" => opts.source_addr = parse_int(&take_val(&mut i)?)? as u8,
            "--ddc-addr" => opts.ddc_addr = parse_int(&take_val(&mut i)?)? as u8,
            "--config-value" => opts.config_value = parse_int(&take_val(&mut i)?)? as u8,
            "--config-speed" => opts.config_speed = parse_int(&take_val(&mut i)?)? as u8,
            "--report-len" => opts.report_len = parse_int(&take_val(&mut i)?)? as usize,
            "--report-id" => opts.report_id = parse_int(&take_val(&mut i)?)? as u8,
            "--slave" => raw_slave = Some(parse_int(&take_val(&mut i)?)? as u8),
            "--data" => raw_data = Some(take_val(&mut i)?),
            other if other.starts_with('-') => {
                return Err(format!("unknown flag: {other}"));
            }
            _ => positional.push(a),
        }
        i += 1;
    }

    if opts.report_len < PAYLOAD_OFFSET {
        return Err(format!(
            "--report-len {} too small (must be >= {})",
            opts.report_len, PAYLOAD_OFFSET
        ));
    }

    let cmd = positional.first().cloned().unwrap_or_default();
    let api = HidApi::new().map_err(|e| format!("hidapi init failed: {e}"))?;

    match cmd.as_str() {
        "" => {
            print!("{}", usage());
            Err("no command given".to_string())
        }
        "list" => cmd_list(&api),
        "switch" => {
            let input = positional
                .get(1)
                .ok_or("switch needs an <input> argument")?;
            cmd_switch(&api, &opts, input)
        }
        "raw-i2c" => {
            let slave = raw_slave.ok_or("raw-i2c needs --slave")?;
            let data_str = raw_data.ok_or("raw-i2c needs --data")?;
            let mut data = Vec::new();
            for tok in data_str.split_whitespace() {
                data.push(parse_int(tok)? as u8);
            }
            if data.is_empty() {
                return Err("--data is empty".to_string());
            }
            cmd_raw_i2c(&api, &opts, slave, &data)
        }
        "getvcp" => {
            let code = positional.get(1).ok_or("getvcp needs a <code> argument")?;
            let code = parse_int(code)? as u8;
            cmd_getvcp(&api, &opts, code)
        }
        other => Err(format!("unknown command: {other}\n\n{}", usage())),
    }
}

fn main() -> ExitCode {
    match run() {
        Ok(()) => ExitCode::SUCCESS,
        Err(e) => {
            eprintln!("error: {e}");
            ExitCode::FAILURE
        }
    }
}
