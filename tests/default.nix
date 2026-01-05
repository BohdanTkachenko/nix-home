{
  self,
  pkgs,
  lib,
}:
let
  testDirs = [
    ./overlays
  ];

  testFiles = lib.flatten (map import testDirs);
  tests = lib.foldl' (acc: file: acc // import file { inherit self lib; }) { } testFiles;
in
builtins.seq
  (lib.debug.throwTestFailures { failures = lib.runTests tests; })
  pkgs.emptyFile
