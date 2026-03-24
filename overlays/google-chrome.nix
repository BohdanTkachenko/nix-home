{
  config,
  lib,
  pkgs,
  browser-previews-pkgs,
  ...
}:
let
  # https://chromium.googlesource.com/chromium/src/+/lkgr/docs/gpu/vaapi.md#vaapi-on-linux
  vaapiEnableFeatures = [
    # An AcceleratedVideoEncoder (AVE) performs high-level, platform-independent
    # encoding process tasks, such as managing codec state, reference frames,
    # etc., but may require support from an external accelerator (typically a
    # hardware accelerator) to offload some stages of the actual encoding
    # process, using the parameters that AVE prepares beforehand.
    "AcceleratedVideoEncoder"

    # The following feature can improve performance when using EGL/Wayland.
    # It is enabled by default, but keeping this just in case.
    "AcceleratedVideoDecodeLinuxZeroCopyGL"

    ## Vulkan

    # Enable Vulkan graphics backend for compositing and rasterization.
    "Vulkan"

    # Use ANGLE's Vulkan backend.
    "DefaultANGLEVulkan"

    # Enable sharing Vulkan device queue with ANGLE's Vulkan backend.
    "VulkanFromANGLE"

    # Enable skipping the Vulkan blocklist.
    #"SkipVulkanBlocklist"

    # Ignore the non-intel driver blacklist for VaapiVideoDecoder
    # implementations.
    "VaapiIgnoreDriverChecks"

    # Enables the use of VA-API for hardware-accelerated video decoding.
    "VaapiVideoDecoder"

    # Enables the use of VA-API for hardware-accelerated video encoding.
    "VaapiVideoEncoder"

    # Enables hardware-accelerated decoding specifically for WebRTC (video calls).
    "WebRtcHWDecoding"

    # Enables hardware-accelerated encoding specifically for WebRTC.
    "WebRtcHWEncoding"

    # Enables hardware-accelerated VP8 encoding for WebRTC.
    "WebRtcHWVP8Encoding"

    # Enables hardware-accelerated VP9 encoding for WebRTC.
    "WebRtcHWVP9Encoding"

    # Generic flag to enable hardware-accelerated video decoding across the browser.
    "AcceleratedVideoDecoder"
  ];
  vaapiFlags = [
    ## Vulkan
    "--use-gl=angle"
    "--use-angle=vulkan"

    # Optional
    # "--ignore-gpu-blocklist"
    # "--disable-gpu-driver-bug-workaround"
  ];

  # Enable Gemini Live in Chrome.
  geminiFeatures = [
    "ContextualCueing"
    "Glic"
    "GlicDevelopmentCookies"
    "GlicKeyboardShortcutNewBadge"
    "GlicRollout"
    "TabstripComboButton"
  ];

  disableFeatures = [
    # Prevent Chrome from capturing hardware media keys (Playy/Pause/etc).
    "HardwareMediaKeyHandling"
  ];

  enableFeatures =
    vaapiEnableFeatures
    ++ geminiFeatures
    ++ [
      # Use dark mode for Chrome internal views.
      "WebUIDarkMode"

      # Enable Gemini in Chrome.
      "ContextualCueing"
    ];

  allFlags = vaapiFlags ++ [
    # Ignore theme reported by OS and use dark mode.
    # TIn certain cases there are issues with GNOME reporting theme correctly.
    "--force-dark-mode"

    # Prevent using RAM to draw web pages. Use graphics card memory instead.
    "--enable-zero-copy"

    # Make scrolling smooth.
    "--enable-smooth-scrolling"

    # Enable GTK4.
    "--gtk-version=4"

    ("--disable-features=" + (builtins.concatStringsSep "," disableFeatures))
    ("--enable-features=" + (builtins.concatStringsSep "," enableFeatures))
  ];
  flagsStr = builtins.concatStringsSep " " allFlags;

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

  mkWrapper =
    pkg: systemBinaryName:
    if !config.my.google.enable then
      pkg.override { commandLineArgs = allFlags; }
    else
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
    {
      pkg = pkgs.google-chrome;
      bin = "google-chrome-stable";
      search = "/opt/google/chrome/google-chrome";
    }
  ];

  autostartFixers = lib.mkMerge (map (c: mkAutostartFixer c.bin c.search) chromeConfigs);
in
{
  nixpkgs.overlays = [
    (final: prev: {
      google-chrome = mkWrapper prev.google-chrome "google-chrome-stable";
    })
  ];

  systemd.user = lib.mkIf config.my.google.enable autostartFixers;
}
