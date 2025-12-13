{ pkgs, lib, ... }:

let
  chrome-wrapper = pkgs.writeShellScriptBin "google-chrome-stable" ''
    #!${pkgs.bash}/bin/bash
    exec /usr/bin/google-chrome-stable \
      --enable-features=AcceleratedVideoEncoder,AcceleratedVideoDecoder,VaapiVideoDecoder,VaapiIgnoreDriverChecks,Vulkan,DefaultANGLEVulkan,VulkanFromANGLE,WebUIDarkMode \
      --force-dark-mode \
      --ignore-gpu-blocklist \
      --disable-gpu-driver-bug-workaround \
      --enable-zero-copy \
      --enable-smooth-scrolling \
      --use-gl=angle \
      --use-angle=vulkan \
      "$@"
  '';

  google-chrome-unwrapped = pkgs.google-chrome;

  patched-desktop-content =
    lib.strings.replaceStrings
      [ "${google-chrome-unwrapped}/bin/google-chrome-stable" ]
      [ "${chrome-wrapper}/bin/google-chrome-stable" ]
      (builtins.readFile "${google-chrome-unwrapped}/share/applications/google-chrome.desktop");

  patched-desktop-file = pkgs.writeText "google-chrome-patched.desktop" patched-desktop-content;

in
{
  home.packages = [
    chrome-wrapper
  ];

  home.file.".local/share/applications/google-chrome.desktop".source = patched-desktop-file;
}
