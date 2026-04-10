{
  nixpkgs.overlays = [
    (self: super:
      let
        pname = "bambu-studio";
        version = "02.00.03.54";

        src = super.fetchurl {
          url = "https://github.com/bambulab/BambuStudio/releases/download/V${version}/Bambu_Studio_linux_fedora-v${version}.AppImage";
          sha256 = "sha256-Fy/ZYQ4kosXvoLADtI3+wmlueytvLUgJiaUwtR2u9pE=";
        };

        extracted = super.appimageTools.extract { inherit pname version src; };
      in
      {
        bambu-studio = super.appimageTools.wrapType2 {
          inherit pname version src;
          name = "BambuStudio";

          profile = ''
            export SSL_CERT_FILE="${super.cacert}/etc/ssl/certs/ca-bundle.crt"
            export GIO_MODULE_DIR="${super.glib-networking}/lib/gio/modules/"
          '';

          extraPkgs =
            pkgs: with pkgs; [
              cacert
              glib
              glib-networking
              gst_all_1.gst-plugins-bad
              gst_all_1.gst-plugins-base
              gst_all_1.gst-plugins-good
              webkitgtk_4_1
            ];

          extraInstallCommands = ''
            mkdir -p $out/share
            ${super.xorg.lndir}/bin/lndir -silent "${extracted}/usr/share" "$out/share"
            mkdir -p $out/share/applications
            cp ${extracted}/BambuStudio.desktop $out/share/applications/
            substituteInPlace $out/share/applications/BambuStudio.desktop \
              --replace-fail 'Exec=AppRun' 'Exec=bambu-studio'
          '';
        };
      })
  ];
}
