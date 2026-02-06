{ lib, ... }:
let
  appDefinitions = {
    googleGemini = {
      name = "Google Gemini";
      url = "https://gemini.google.com";
      categories = [
        "Development"
        "Utility"
        "Network"
      ];
      genericName = "AI assistant";
      icon = builtins.fetchurl {
        name = "googleGemini.svg";
        url = "https://www.gstatic.com/lamda/images/gemini_sparkle_aurora_33f86dc0c0257da337c63.svg";
        sha256 = "1cyc3csq8y8lgrqfr5mp4wdhm36ngazn6z1kv9bh436whqzz6vgm";
      };
    };

    googleMeet = {
      name = "Google Meet";
      url = "https://meet.google.com";
      categories = [
        "VideoConference"
        "Network"
      ];
      genericName = "Video conferencing";
      icon = builtins.fetchurl {
        name = "googleMeet.svg";
        url = "https://www.gstatic.com//meet/icons/logo_meet_2020q4_512dp_4ac4a724a69a35b5b08c6a711c9717c2.png";
        sha256 = "0n47sbbry25d1hdjrr7r2zygfpaimzizv9hm1smlxn8ghksmhnif";
      };
    };

    googleMessages = {
      name = "Google Messages";
      url = "https://messages.google.com/web/?pwa=1";
      categories = [
        "Chat"
        "InstantMessaging"
        "Network"
      ];
      genericName = "SMS messaging";
      icon = builtins.fetchurl {
        name = "googleMessages.png";
        url = "https://ssl.gstatic.com/android-messages-web/images/2022.3/1x/messages_2022_round_512dp.png";
        sha256 = "0ka5hzllrgy0cndv082zqjjrx2labz0ivmjc9mj63cd4c1c0f7mh";
      };
    };

    facebookMessenger = {
      name = "Facebook Messenger";
      url = "https://www.messenger.com/";
      categories = [
        "Chat"
        "InstantMessaging"
        "Network"
      ];
      genericName = "Instant messaging";
      icon = builtins.fetchurl {
        name = "facebookMessenger.svg";
        url = "https://static.xx.fbcdn.net/rsrc.php/yu/r/f-G52KjuPy1.svg?_nc_eui2=AeHzQieJxZKjxFVelhLkxhLJxMQscGEQ327ExCxwYRDfbkf_81bMayBxxtQmp5OI1oY";
        sha256 = "0vys9pvyaagd7mbrmpzfcbvh5mszqfbpn7dy49sxl1cr8ficqfa2";
      };
    };

    whatsApp = {
      name = "WhatsApp";
      url = "https://web.whatsapp.com";
      categories = [
        "Chat"
        "InstantMessaging"
        "Network"
      ];
      genericName = "Messaging application";
      icon = builtins.fetchurl {
        name = "whatsapp.svg";
        url = "https://static.whatsapp.net/rsrc.php/yp/r/iBj9rlryvZv.svg";
        sha256 = "1qji1a1kxcx77f4v0xjfkzkqyvkzwp0nf3479r40ahrr8iv5aqs2";
      };
    };

    youtube = {
      name = "YouTube";
      url = "https://youtube.com";
      categories = [
        "AudioVideo"
        "Video"
        "Network"
      ];
      genericName = "Video streaming";
      icon = builtins.fetchurl {
        name = "youtube.png";
        url = "https://www.gstatic.com/youtube/img/branding/favicon/favicon_192x192_v2.png";
        sha256 = "0dg9nf97f9rav2jj04l1jc7r2zqzwp80g7n7k59brsjgrd0ps31n";
      };
    };
  };
in
{
  nixpkgs.overlays = [
    (final: prev: {
      webApps =
        let
          browsers = {
            stable = {
              package = final.google-chrome;
              bin = "google-chrome-stable";
              channel = "stable";
              suffix = "";
              profile = "Default";
            };
            beta = {
              package = final.google-chrome-beta;
              bin = "google-chrome-beta";
              channel = "beta";
              suffix = " (Beta)";
              profile = "Profile_1";
            };
            dev = {
              package = final.google-chrome-dev;
              bin = "google-chrome-unstable";
              channel = "unstable";
              suffix = " (Unstable)";
              profile = "Profile_2";
            };
          };

          # Generate Chrome app WM class from URL (e.g., "https://web.whatsapp.com" -> "chrome-web.whatsapp.com__-Default")
          mkWMClass =
            url: profile:
            let
              withoutScheme = builtins.elemAt (lib.splitString "://" url) 1;
              host = builtins.head (lib.splitString "/" withoutScheme);
            in
            "chrome-${host}__-${profile}";

          mkWebApp =
            browser:
            {
              name,
              url,
              icon ? "google-chrome",
              categories ? [ "Network" ],
              genericName ? "",
              startupNotify ? true,
              startupWMClass ? mkWMClass url browser.profile,
            }:
            let
              sanitizedName = lib.toLower (builtins.replaceStrings [ " " ] [ "-" ] name);
              binaryName = "${sanitizedName}-${browser.channel}";
              desktopItem = final.makeDesktopItem {
                name = name;
                exec = binaryName;
                desktopName = "${name}${browser.suffix}";
                inherit
                  icon
                  genericName
                  categories
                  startupNotify
                  startupWMClass
                  ;
              };

              script = final.writeScriptBin binaryName ''
                #!${final.runtimeShell}
                exec ${browser.package}/bin/${browser.bin} \
                  --app=${lib.escapeShellArg url} \
                  --no-first-run \
                  --no-default-browser-check \
                  --no-crash-upload \
                  "$@"
              '';
            in
            final.symlinkJoin {
              name = binaryName;
              paths = [
                script
                desktopItem
              ];
              passthru = {
                inherit binaryName;
                desktopFile = "${binaryName}.desktop";
              };
            };

          mkAppsForBrowser = browser: lib.mapAttrs (_: mkWebApp browser) appDefinitions;
        in
        {
          stable = mkAppsForBrowser browsers.stable;
          beta = mkAppsForBrowser browsers.beta;
          dev = mkAppsForBrowser browsers.dev;
        };
    })
  ];
}
