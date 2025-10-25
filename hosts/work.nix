{ ... }:
{
  home.stateVersion = "25.05";
  home.username = "bohdant";
  home.homeDirectory = "/home/bohdant";

  nixpkgs.config.allowUnfree = true;

  programs.home-manager.enable = true;
  targets.genericLinux.enable = true;

  programs.chromium-pwa-wmclass-sync.service.enable = true;

  dconf.settings = {
    "org/gnome/shell" = {
      favorite-apps = [
        "chrome-kcnapeopnfjnjabihlnncilmkjbjjipg-Default.desktop" # Gemini
        "chrome-ahdfkjhgpgcbfkeoehapbdafbjlnpejh-Default.desktop" # Duckie
        "google-chrome.desktop"
        "chrome-apkjikbjlghbonboeaehkeoadefnfjmb-Default.desktop" # Cider
        "org.gnome.Ptyxis.desktop"
        "chrome-fmgjjmmmlfnkbppncabfkddbjimcfncm-Default.desktop" # Gmail
        "chrome-pommaclcbfghclhalboakcipcmmndhcj-Default.desktop" # Google Chat
        "chrome-kjbdgfilnfhdoflbpgamdcdgpehopbep-Default.desktop" # Google Calender
        "spotify.desktop"
        "chrome-hnpfjngllnobngcgfapefoaidbinmjnm-Profile_1.desktop" # WhatsApp
        "1password.desktop"
      ];
    };
  };

  imports = [
    ../modules/1password
    ../modules/fonts
    ../modules/bash.nix
    ../modules/fish.nix
    ../modules/git
    ../modules/git/personal.nix
    ../modules/gnome.nix
    ../modules/ptyxis
    ../modules/ssh
    ../modules/ssh/work.nix
    ../modules/micro.nix
    ../modules/tools.nix
    ../modules/vscode/vscode.nix
  ];

  services.xremap = {
    enable = true;
    withGnome = true;
    deviceNames = [
      "AT Translated Set 2 keyboard"
      "ThinkPad Extra Buttons"
    ];
    config.modmap = [
      {
        name = "Put modifier keys in more usable places";
        remap = {
          "Alt_L" = "Control_L";
          "Super_L" = "Alt_L";
          "Control_L" = "Super_L";
        };
      }
      {
        name = "Make CapsLock useful";
        remap = {
          "CapsLock" = "Backspace";
        };
      }
      {
        name = "Remap special function keys to media keys";
        remap = {
          # "KEY_447" = "KEY_PLAYPAUSE";
          "KEY_SWITCHVIDEOMODE" = "KEY_PLAYPAUSE";
          "KEY_SELECTIVE_SCREENSHOT" = "KEY_PREVIOUSSONG";
          "KEY_PICKUP_PHONE" = "KEY_PREVIOUSSONG";
          "KEY_HANGUP_PHONE" = "KEY_PLAYPAUSE";
          "KEY_BOOKMARKS" = "KEY_NEXTSONG";
        };
      }
    ];
  };
}
