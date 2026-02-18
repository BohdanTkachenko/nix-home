{
  nixpkgs.overlays = [
    (self: super:
      let
        pname = "bambu-studio";
        version = "02.05.00.67";
        ubuntu_version = "24.04_PR-9540";

        src = super.fetchurl {
          url = "https://github.com/bambulab/BambuStudio/releases/download/v${version}/Bambu_Studio_ubuntu-${ubuntu_version}.AppImage";
          sha256 = "sha256-3ubZblrsOJzz1p34QiiwiagKaB7nI8xDeadFWHBkWfg=";
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
