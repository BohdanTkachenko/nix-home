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
        name = "googleGemini.png";
        url = "https://www.gstatic.com/images/branding/product/2x/gemini_512dp.png";
        sha256 = "127bb7s1mmlki2x4gh01lwah1pwrwwmdh061x8ivcq1vabxzs7i3";
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
        name = "googleMeet.png";
        url = "https://www.gstatic.com//meet/icons/logo_meet_2020q4_512dp_4ac4a724a69a35b5b08c6a711c9717c2.png";
        sha256 = "0n47sbbry25d1hdjrr7r2zygfpaimzizv9hm1smlxn8ghksmhnif";
      };
    };

    googleCalendar = {
      name = "Google Calendar";
      url = "https://calendar.google.com";
      categories = [
        "Calendar"
        "Network"
      ];
      genericName = "Calendar";
      icon = builtins.fetchurl {
        name = "googleCalendar.png";
        url = "https://www.gstatic.com/images/branding/product/2x/calendar_512dp.png";
        sha256 = "065wk88jr78m62kxw70prl5ap0kl28d05qlacgnixbmnhvllzvvf";
      };
    };

    gmail = {
      name = "Gmail";
      url = "https://mail.google.com";
      categories = [
        "Email"
        "Network"
      ];
      genericName = "Email client";
      icon = builtins.fetchurl {
        name = "gmail.png";
        url = "https://www.gstatic.com/images/branding/product/2x/gmail_512dp.png";
        sha256 = "09wmr05mzq2snyxbb0qfyg8qlly6h07p2jx1zf8d7sq9fxsa4735";
      };
    };

    googleChat = {
      name = "Google Chat";
      url = "https://chat.google.com";
      categories = [
        "Chat"
        "InstantMessaging"
        "Network"
      ];
      genericName = "Instant messaging";
      icon = builtins.fetchurl {
        name = "googleChat.png";
        url = "https://www.gstatic.com/images/branding/product/2x/chat_512dp.png";
        sha256 = "0mfhm2m3l0hvdf5c2q4mybyggmzfgy30b479y0m15q08xj03k3h2";
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
        url = "https://www.gstatic.com/images/branding/product/2x/messages_512dp.png";
        sha256 = "0ccmhzsaxxfi61nbazc9zarqnab6d7lv03drgzwrn7f337zfir1m";
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
        url = "https://www.gstatic.com/images/branding/product/2x/youtube_512dp.png";
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
                name = binaryName;
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
