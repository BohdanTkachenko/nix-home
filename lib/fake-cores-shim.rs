//! LD_PRELOAD shim: makes the host process (and the children it spawns) believe
//! the machine has `CLAUDE_FAKE_CORES` logical CPUs (default 20).
//!
//! Why: Claude Code caps workflow ("ultracode") subagent concurrency at
//! `min(16, cores - 2)`. On the 4-vCPU aarch64 cloud workbench that floors the
//! cap at 2 — even though the agents are I/O-bound (idle on the API) and
//! oversubscribe the real cores happily. Faking >= 18 cores lifts the cap to
//! its hard ceiling of 16.
//!
//! Claude is a Bun-compiled binary; strace shows it counts cores via
//! `sched_getaffinity` plus glibc's `sysconf(_SC_NPROCESSORS_ONLN)` (which reads
//! `/sys/devices/system/cpu/online`). It never touches `/proc/stat`. Overriding
//! these libc entry points fakes the count without any namespace or privilege.
#![no_std]
#![allow(non_camel_case_types)]
use core::ffi::{c_char, c_int, c_long, c_void};

#[panic_handler]
fn ph(_: &core::panic::PanicInfo) -> ! {
    loop {}
}

extern "C" {
    fn getenv(name: *const c_char) -> *mut c_char;
    fn dlsym(handle: *mut c_void, symbol: *const c_char) -> *mut c_void;
}

/// Number of CPUs to report: `$CLAUDE_FAKE_CORES` if a positive integer, else 20.
fn fake() -> usize {
    unsafe {
        let p = getenv(b"CLAUDE_FAKE_CORES\0".as_ptr() as *const c_char) as *const u8;
        if p.is_null() {
            return 20;
        }
        let (mut n, mut i, mut any) = (0usize, 0isize, false);
        loop {
            let c = *p.offset(i);
            if c == 0 {
                break;
            }
            if !(b'0'..=b'9').contains(&c) {
                return 20;
            }
            n = n.wrapping_mul(10).wrapping_add((c - b'0') as usize);
            any = true;
            i += 1;
        }
        if any && n > 0 {
            n
        } else {
            20
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn sched_getaffinity(
    _pid: c_int,
    cpusetsize: usize,
    mask: *mut c_void,
) -> c_int {
    if mask.is_null() || cpusetsize == 0 {
        return 0;
    }
    core::ptr::write_bytes(mask as *mut u8, 0, cpusetsize);
    let bytes = mask as *mut u8;
    let max_bits = cpusetsize * 8;
    let n = fake();
    let mut i = 0;
    while i < n && i < max_bits {
        *bytes.add(i / 8) |= 1u8 << (i % 8);
        i += 1;
    }
    0
}

#[no_mangle]
pub extern "C" fn get_nprocs() -> c_int {
    fake() as c_int
}

#[no_mangle]
pub extern "C" fn get_nprocs_conf() -> c_int {
    fake() as c_int
}

const SC_NPROCESSORS_CONF: c_int = 83;
const SC_NPROCESSORS_ONLN: c_int = 84;
const RTLD_NEXT: *mut c_void = -1isize as *mut c_void;

#[no_mangle]
pub unsafe extern "C" fn sysconf(name: c_int) -> c_long {
    if name == SC_NPROCESSORS_ONLN || name == SC_NPROCESSORS_CONF {
        return fake() as c_long;
    }
    let sym = dlsym(RTLD_NEXT, b"sysconf\0".as_ptr() as *const c_char);
    let real: extern "C" fn(c_int) -> c_long = core::mem::transmute(sym);
    real(name)
}
