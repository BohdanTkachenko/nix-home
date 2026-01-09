{ lib, pkgs, browser-previews-pkgs, isWork, ... }:
{
  nixpkgs.overlays = [
    (final: prev:
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
        autostartFixerEnv = pkgs.buildEnv {
          name = "fix-chrome-autostart-env";
          paths = [ autostartFixerScript pkgs.python3 ];
        };

        mkWrapper = pkg: systemBinaryName: searchFor:
          if !isWork then pkg.override { commandLineArgs = customFlags; } else
            pkgs.stdenv.mkDerivation {
              pname = final.lib.getName pkg;
              version = pkg.version;
              src = pkgs.lib.cleanSource ../.;
              dontUnpack = true;

              installPhase = ''
                runHook preInstall

                # 1. Create Wrapper Script
                mkdir -p $out/bin
                cat > $out/bin/${systemBinaryName} << EOF
                #!${pkgs.stdenv.shell}
                exec "/usr/bin/${systemBinaryName}" ${flagsStr} "$@"
                EOF
                chmod +x $out/bin/${systemBinaryName}

                # 2. Create Desktop Item
                mkdir -p $out/share/applications
                for sourceDesktop in $(find "${pkg}/share/applications" -iname "*.desktop"); do
                  outDesktopFile="$out/share/applications/$(basename "$sourceDesktop")"
                  cp "$sourceDesktop" "$outDesktopFile"
                  sed -i "s|\(${final.lib.getExe pkg}\)\(.*\)|"/usr/bin/${systemBinaryName}" ${flagsStr}\2|g" "$outDesktopFile"
                done

                # 3. Create Systemd Units
                mkdir -p $out/lib/systemd/user
                unit_name="fix-${systemBinaryName}-autostart"
                # Service File
                cat > $out/lib/systemd/user/$unit_name.service << EOF
                [Unit]
                Description=Fix ${systemBinaryName} autostart files
                [Service]
                Type=oneshot
                Environment="PATH=${autostartFixerEnv}/bin"
                IOSchedulingClass=idle
                IOSchedulingPriority=7
                ExecStart=${autostartFixerScript}/bin/fix-chrome-autostart ${lib.escapeShellArg searchFor} ${lib.escapeShellArg systemBinaryName}
                EOF
                # Path File
                cat > $out/lib/systemd/user/$unit_name.path << EOF
                [Unit]
                Description=Watch for changes in ${systemBinaryName} autostart files
                [Path]
                PathChanged=%h/.config/autostart/
                [Install]
                WantedBy=paths.target
                EOF

                runHook postInstall
              '';

              postFixup = ''
                # The default fixup phase moves systemd units to share/ and creates a
                # symlink in lib/, which breaks home-manager's unit discovery.
                # This hook runs after the fixup and enforces the structure that
                # home-manager expects.
                rm -f $out/lib/systemd/user
                mkdir -p $out/lib/systemd/user
                mv $out/share/systemd/user/* $out/lib/systemd/user/
                rmdir --ignore-fail-on-non-empty $out/share/systemd/user
                rmdir --ignore-fail-on-non-empty $out/share/systemd
              '';
            };
      in
      {
        google-chrome = mkWrapper prev.google-chrome "google-chrome-stable" "/opt/google/chrome/google-chrome";
        google-chrome-beta = mkWrapper browser-previews-pkgs.google-chrome-beta "google-chrome-beta" "/opt/google/chrome-beta/google-chrome-beta";
        google-chrome-dev = mkWrapper browser-previews-pkgs.google-chrome-dev "google-chrome-unstable" "/opt/google/chrome-unstable/google-chrome";
      })
  ];
}

