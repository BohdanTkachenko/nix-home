{ rustPlatform, pkg-config, udev }:

rustPlatform.buildRustPackage {
  pname = "lg-usb-ddc";
  version = "0.1.0";
  src = ./.;
  cargoLock.lockFile = ./Cargo.lock;
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ udev ]; # hidapi-rs links libudev
}
