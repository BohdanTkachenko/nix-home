# Desktop environment configuration (GNOME, audio, display)
{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf config.my.gui.enable {
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber.extraConfig."50-disable-cards" = {
        "monitor.alsa.rules" = [
          {
            matches = [
              { "device.name" = "alsa_card.pci-0000_03_00.1"; } # Navi 31 HDMI/DP Audio
              { "device.name" = "alsa_card.pci-0000_7c_00.1"; } # Radeon iGPU HD Audio
              { "device.name" = "alsa_card.pci-0000_7c_00.6"; } # Ryzen HD Audio Controller
            ];
            actions.update-props."device.disabled" = true;
          }
          {
            matches = [
              { "device.name" = "~alsa_card\\.usb-Sennheiser_EPOS_GSX_300_.*-00"; }
            ];
            actions.update-props = {
              "device.description" = "Headphones";
              "device.nick" = "Headphones";
              "api.acp.hidden-profiles" =
                ''[ "output:iec958-stereo", "output:iec958-stereo+input:mono-fallback", "pro-audio" ]'';
              "api.acp.hidden-ports" = ''[ "iec958-stereo-output" ]'';
            };
          }
          {
            matches = [
              { "device.name" = "~alsa_card\\.usb-Generic_USB_SPDIF_Adapter_.*-00"; }
            ];
            actions.update-props = {
              "device.description" = "Soundbar";
              "device.nick" = "Soundbar";
              "api.acp.hidden-profiles" = ''[ "output:iec958-stereo", "pro-audio" ]'';
              "api.acp.hidden-ports" = ''[ "iec958-stereo-output" ]'';
            };
          }
          {
            matches = [
              { "device.name" = "alsa_card.usb-046d_Logitech_BRIO_827A05B4-03"; }
            ];
            actions.update-props = {
              "device.description" = "Webcam";
              "device.nick" = "Webcam";
              "api.acp.hidden-profiles" = ''[ "input:iec958-stereo", "pro-audio" ]'';
              "api.acp.hidden-ports" = ''[ "iec958-stereo-input" ]'';
            };
          }
          {
            matches = [
              { "node.name" = "~alsa_output\\.usb-Sennheiser_EPOS_GSX_300_.*-00\\.analog-stereo"; }
              { "node.name" = "~alsa_input\\.usb-Sennheiser_EPOS_GSX_300_.*-00\\.mono-fallback"; }
            ];
            actions.update-props = {
              "node.description" = "Headphones";
              "node.nick" = "Headphones";
            };
          }
          {
            matches = [
              { "node.name" = "~alsa_output\\.usb-Generic_USB_SPDIF_Adapter_.*-00\\.analog-stereo"; }
            ];
            actions.update-props = {
              "node.description" = "Soundbar";
              "node.nick" = "Soundbar";
            };
          }
          {
            matches = [
              { "node.name" = "~alsa_(input|output)\\..*\\.pro-(input|output)-.*"; }
              { "node.name" = "~alsa_output\\.usb-Sennheiser_EPOS_GSX_300_.*-00\\.iec958-stereo"; }
            ];
            actions.update-props."node.disabled" = true;
          }
        ];
      };
    };

    services.xserver.enable = true;
    services.displayManager.gdm.enable = true;
    services.desktopManager.gnome.enable = true;

    services.flatpak.enable = true;

    systemd.services.flatpak-repo = {
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.flatpak ];
      script = ''
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
      '';
    };

    programs.xwayland.enable = true;

    environment.gnome.excludePackages = (
      with pkgs;
      [
        gnome-tour
      ]
    );

    environment.systemPackages =
      with pkgs;
      [
        google-chrome
        protontricks
      ]
      ++ (with gst_all_1; [
        gstreamer
        gst-plugins-base
        gst-plugins-good
        gst-plugins-bad
        gst-plugins-ugly
        gst-libav
        gst-vaapi
      ]);
  };
}
