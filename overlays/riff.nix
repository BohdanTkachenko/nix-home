{
  lib,
  stdenv,
  fetchFromGitHub,
  rustPlatform,
  cargo,
  rustc,
  meson,
  ninja,
  pkg-config,
  wrapGAppsHook4,
  blueprint-compiler,
  desktop-file-utils,
  appstream-glib,
  gettext,
  glib,
  gtk4,
  libadwaita,
  openssl,
  alsa-lib,
  libpulseaudio,
  gst_all_1,
}:
stdenv.mkDerivation rec {
  pname = "riff";
  version = "25.11";

  src = fetchFromGitHub {
    owner = "Diegovsky";
    repo = "riff";
    rev = "refs/tags/v${version}";
    hash = "sha256-j5PZXXGInA03V3Lfu+QUgeHw8583XvJZyW67VcDe980=";
  };

  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit pname version src;
    hash = "sha256-8gJILK9A97PAb/Q1z+IvW54WuwoZZSKxlJJUt7dwQWE=";
  };

  postPatch = ''
    substituteInPlace src/meson.build --replace-fail \
      "cargo_output = 'src' / rust_target / meson.project_name()" \
      "cargo_output = 'src' / '${stdenv.hostPlatform.rust.cargoShortTarget}' / rust_target / meson.project_name()"
  '';

  nativeBuildInputs = [
    appstream-glib
    blueprint-compiler
    cargo
    desktop-file-utils
    gettext
    glib
    gtk4
    meson
    ninja
    pkg-config
    rustPlatform.cargoSetupHook
    rustc
    wrapGAppsHook4
  ];

  buildInputs = [
    alsa-lib
    glib
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gstreamer
    gtk4
    libadwaita
    libpulseaudio
    openssl
  ];

  mesonBuildType = "release";

  env.CARGO_BUILD_TARGET = stdenv.hostPlatform.rust.rustcTargetSpec;

  preFixup = ''
    gappsWrapperArgs+=(
      --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "$GST_PLUGIN_SYSTEM_PATH_1_0"
    )
  '';

  meta = {
    description = "Native Spotify client for the GNOME desktop (fork of Spot)";
    homepage = "https://github.com/Diegovsky/riff";
    license = lib.licenses.mit;
    mainProgram = "riff";
    platforms = lib.platforms.linux;
  };
}
