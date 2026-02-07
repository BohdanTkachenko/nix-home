# Tests for web-apps overlay
#
# Chrome's WM_CLASS format for --app mode:
#   chrome-{host}__{path_segments}-{profile}
#
# Examples:
#   https://web.whatsapp.com        -> chrome-web.whatsapp.com__-Default
#   https://messages.google.com/web/ -> chrome-messages.google.com__web_-Default
#   https://www.messenger.com/       -> chrome-www.messenger.com__-Default
#
{ self, lib }:
let
  pkgs = self.nixosConfigurations.nyancat.pkgs;

  # Extract mkWMClass logic for testing (mirrors the overlay implementation)
  mkWMClass =
    url: profile:
    let
      withoutScheme = builtins.elemAt (lib.splitString "://" url) 1;
      withoutQuery = builtins.head (lib.splitString "?" withoutScheme);
      parts = lib.splitString "/" withoutQuery;
      host = builtins.head parts;
      pathParts = builtins.tail parts;
      pathStr = lib.concatStringsSep "_" pathParts;
    in
    "chrome-${host}__${pathStr}-${profile}";
in
{
  # Test URLs without paths (host only)
  wmclass-host-only = {
    expr = mkWMClass "https://web.whatsapp.com" "Default";
    expected = "chrome-web.whatsapp.com__-Default";
    description = "Host-only URL should generate WM class with __ separator";
  };

  wmclass-host-only-gemini = {
    expr = mkWMClass "https://gemini.google.com" "Default";
    expected = "chrome-gemini.google.com__-Default";
    description = "Gemini URL should generate correct WM class";
  };

  # Test URLs with paths
  wmclass-with-path = {
    expr = mkWMClass "https://messages.google.com/web/" "Default";
    expected = "chrome-messages.google.com__web_-Default";
    description = "URL with path should include path with __ after host";
  };

  # Test URLs with query strings (should be stripped)
  wmclass-with-query = {
    expr = mkWMClass "https://messages.google.com/web/?pwa=1" "Default";
    expected = "chrome-messages.google.com__web_-Default";
    description = "Query string should be stripped from WM class";
  };

  # Test different profiles
  wmclass-beta-profile = {
    expr = mkWMClass "https://web.whatsapp.com" "Profile_1";
    expected = "chrome-web.whatsapp.com__-Profile_1";
    description = "Beta profile should use Profile_1";
  };

  # Test trailing slash handling
  wmclass-trailing-slash = {
    expr = mkWMClass "https://www.messenger.com/" "Default";
    expected = "chrome-www.messenger.com__-Default";
    description = "Trailing slash should produce __ before profile";
  };

  # Verify actual generated desktop file has correct StartupWMClass
  desktop-file-whatsapp-wmclass = {
    expr =
      let
        desktopContent = builtins.readFile "${pkgs.webApps.stable.whatsApp}/share/applications/whatsapp-stable.desktop";
      in
      lib.hasInfix "StartupWMClass=chrome-web.whatsapp.com__-Default" desktopContent;
    expected = true;
    description = "WhatsApp desktop file should have correct StartupWMClass";
  };

  desktop-file-messages-wmclass = {
    expr =
      let
        desktopContent = builtins.readFile "${pkgs.webApps.stable.googleMessages}/share/applications/google-messages-stable.desktop";
      in
      lib.hasInfix "StartupWMClass=chrome-messages.google.com__web_-Default" desktopContent;
    expected = true;
    description = "Google Messages desktop file should have correct StartupWMClass";
  };

  # Verify script uses --class flag
  script-has-class-flag = {
    expr =
      let
        scriptContent = builtins.readFile "${pkgs.webApps.stable.whatsApp}/bin/whatsapp-stable";
      in
      lib.hasInfix "--class=" scriptContent;
    expected = true;
    description = "Launch script should include --class flag";
  };
}
