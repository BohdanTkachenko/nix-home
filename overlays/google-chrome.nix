{ browser-previews-pkgs, isWork, ... }:
let
  customFlags = [
    "--disable-features=HardwareMediaKeyHandling"
    "--enable-features=AcceleratedVideoEncoder,WebUIDarkMode"
    "--force-dark-mode"
    "--ignore-gpu-blocklist"
    "--disable-gpu-driver-bug-workaround"
    "--enable-zero-copy"
    "--enable-smooth-scrolling"
  ];
  flagsStr = builtins.concatStringsSep " " customFlags;

  mkWrapper =
    final: pkg: systemBinaryName:
    if !isWork then
      pkg.override { commandLineArgs = customFlags; }
    else
      let
        name = final.lib.getName pkg;
        systemBinaryPath = "/usr/bin/${systemBinaryName}";
        chromeWrapper = final.writeShellScriptBin systemBinaryName ''
          exec "${systemBinaryPath}" ${flagsStr} "$@"
        '';
        desktopItem = final.runCommand "${name}-desktop" { } ''
          mkdir -p "$out/share/applications"
          for sourceDesktop in $(find "${pkg}/share/applications" -iname "*.desktop"); do
            outDesktopFile="$out/share/applications/$(basename "$sourceDesktop")"
            cp "$sourceDesktop" "$outDesktopFile"
            sed -i "s|\(${final.lib.getExe pkg}\)\(.*\)|"${systemBinaryPath}" ${flagsStr}\2|g" "$outDesktopFile"
          done
        '';
      in
      final.symlinkJoin {
        name = "${name}-system-wrapped";
        paths = [
          chromeWrapper
          desktopItem
        ];
      };
in
{
  nixpkgs.overlays = [
    (final: prev: {
      google-chrome = mkWrapper final prev.google-chrome "google-chrome-stable";
      google-chrome-beta = mkWrapper final browser-previews-pkgs.google-chrome-beta "google-chrome-beta";
    })
  ];
}
