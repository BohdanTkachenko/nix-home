{ isWork, ... }:
let
  customFlags = [
    "--enable-features=AcceleratedVideoEncoder,AcceleratedVideoDecoder,VaapiVideoDecoder,VaapiIgnoreDriverChecks,WebUIDarkMode"
    "--force-dark-mode"
    "--ignore-gpu-blocklist"
    "--disable-gpu-driver-bug-workaround"
    "--enable-zero-copy"
    "--enable-smooth-scrolling"
  ];
  flagsStr = builtins.concatStringsSep " " customFlags;
in
{
  nixpkgs.overlays = [
    (final: prev: {
      google-chrome =
        if !isWork then
          prev.google-chrome.override { commandLineArgs = customFlags; }
        else
          let
            wrapperName = "google-chrome-stable";
            chromeWrapper = final.writeShellScriptBin wrapperName ''
              exec /usr/bin/google-chrome-stable ${flagsStr} "$@"
            '';
            desktopItem = final.runCommand "google-chrome-desktop" { } ''
              mkdir -p $out/share/applications
              cp ${prev.google-chrome}/share/applications/google-chrome.desktop $out/share/applications/google-chrome.desktop
              sed -i 's|^Exec=.*|Exec=${chromeWrapper}/bin/${wrapperName} %U|' $out/share/applications/google-chrome.desktop
            '';
          in
          final.symlinkJoin {
            name = "google-chrome-system-wrapped";
            paths = [
              chromeWrapper
              desktopItem
            ];
          };
    })
  ];
}
