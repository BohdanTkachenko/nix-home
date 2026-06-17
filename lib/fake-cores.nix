# Wrap a package so its executables believe the machine has more logical CPUs
# than it physically does, by LD_PRELOAD-ing a tiny Rust shim (see
# ./fake-cores-shim.rs) that overrides every CPU-counting libc surface:
# sched_getaffinity, get_nprocs(_conf) and sysconf(_SC_NPROCESSORS_*).
#
# Purpose: Claude Code caps workflow ("ultracode") subagent concurrency at
# `min(16, cores - 2)`. On the 4-vCPU aarch64 cloud workbench that floors the cap
# at 2, even though the agents are I/O-bound (idle on the API) and oversubscribe
# the real cores happily. Reporting 20 cores lifts the cap to its 16 ceiling.
#
# The fake count is `CLAUDE_FAKE_CORES` (default 20); override at runtime to
# tune. This is a workbench (aarch64) concern only: the x86_64 desktops have 32
# real threads, so the cap already maxes at 16 and the wrapper is a no-op
# pass-through there (mirroring lib/pin-to-ccd1.nix's arch gate).
#
# Usage:
#   let fakeCores = import ../../lib/fake-cores.nix { inherit pkgs; };
#   in fakeCores pkgs.claude-code
{ pkgs }:
let
  shim =
    pkgs.runCommandCC "claude-fake-cores-shim" { nativeBuildInputs = [ pkgs.rustc ]; }
      ''
        mkdir -p $out/lib
        rustc --edition 2021 --crate-type cdylib -C opt-level=2 -C panic=abort \
          -o $out/lib/libfakecores.so ${./fake-cores-shim.rs}
      '';
in
pkg:
# Faking cores only matters where the real count throttles the cap, i.e. the
# aarch64 workbench. Elsewhere, pass the package through unchanged.
if !pkgs.stdenv.hostPlatform.isAarch64 then
  pkg
else
  pkgs.symlinkJoin {
    name = "${pkg.pname or pkg.name or "pkg"}-fakecores";
    paths = [ pkg ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    # Forward attrs downstream modules read off the package; symlinkJoin drops them.
    meta = pkg.meta or { };
    pname = pkg.pname or pkg.name or "pkg";
    version = pkg.version or "0";
    postBuild = ''
      for bin in $out/bin/*; do
        [ -e "$bin" ] && [ -x "$bin" ] || continue
        wrapProgram "$bin" \
          --set-default CLAUDE_FAKE_CORES 20 \
          --prefix LD_PRELOAD : "${shim}/lib/libfakecores.so"
      done
    '';
  }
