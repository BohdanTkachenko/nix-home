{ lib, pkgs, browser-previews-pkgs, isWork, ... }:
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

  autostartFixerScript = pkgs.stdenv.mkDerivation {
    pname = "fix-chrome-autostart-script";
    version = "0.1.0";
    nativeBuildInputs = [ pkgs.python3 ];
    src = ./fix-chrome-autostart.py;
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/fix-chrome-autostart
      chmod +x $out/bin/fix-chrome-autostart
      patchShebangs $out/bin/fix-chrome-autostart
    '';
  };

  mkWrapper = pkg: systemBinaryName:
    if !isWork then pkg.override { commandLineArgs = customFlags; } else
      pkgs.stdenv.mkDerivation {
        pname = lib.getName pkg;
        version = pkg.version;
        dontUnpack = true;

        installPhase = ''
          runHook preInstall

          # Create Wrapper Script
          mkdir -p $out/bin
          cat > $out/bin/${systemBinaryName} << 'WRAPPER'
          #!${pkgs.stdenv.shell}
          exec "/usr/bin/${systemBinaryName}" ${flagsStr} "$@"
          WRAPPER
          chmod +x $out/bin/${systemBinaryName}

          # Create Desktop Item
          mkdir -p $out/share/applications
          for sourceDesktop in $(find "${pkg}/share/applications" -iname "*.desktop"); do
            outDesktopFile="$out/share/applications/$(basename "$sourceDesktop")"
            cp "$sourceDesktop" "$outDesktopFile"
            sed -i "s|\(${lib.getExe pkg}\)\(.*\)|/usr/bin/${systemBinaryName} ${flagsStr}\2|g" "$outDesktopFile"
          done

          runHook postInstall
        '';
      };

  mkAutostartFixer = systemBinaryName: searchFor: {
    services."fix-${systemBinaryName}-autostart" = {
      Unit.Description = "Fix ${systemBinaryName} autostart files";
      Service = {
        Type = "oneshot";
        ExecStart = "${autostartFixerScript}/bin/fix-chrome-autostart ${lib.escapeShellArg searchFor} ${lib.escapeShellArg systemBinaryName}";
        IOSchedulingClass = "idle";
        IOSchedulingPriority = 7;
      };
    };
    paths."fix-${systemBinaryName}-autostart" = {
      Unit.Description = "Watch for changes in ${systemBinaryName} autostart files";
      Path.PathChanged = "%h/.config/autostart/";
      Install.WantedBy = [ "paths.target" ];
    };
  };

  chromeConfigs = [
    { pkg = pkgs.google-chrome; bin = "google-chrome-stable"; search = "/opt/google/chrome/google-chrome"; }
    { pkg = browser-previews-pkgs.google-chrome-beta; bin = "google-chrome-beta"; search = "/opt/google/chrome-beta/google-chrome-beta"; }
    { pkg = browser-previews-pkgs.google-chrome-dev; bin = "google-chrome-unstable"; search = "/opt/google/chrome-unstable/google-chrome"; }
  ];

  autostartFixers = lib.mkMerge (map (c: mkAutostartFixer c.bin c.search) chromeConfigs);
in
{
  nixpkgs.overlays = [
    (final: prev: {
      google-chrome = mkWrapper prev.google-chrome "google-chrome-stable";
      google-chrome-beta = mkWrapper browser-previews-pkgs.google-chrome-beta "google-chrome-beta";
      google-chrome-dev = mkWrapper browser-previews-pkgs.google-chrome-dev "google-chrome-unstable";
    })
  ];

  systemd.user = lib.mkIf isWork autostartFixers;
}

