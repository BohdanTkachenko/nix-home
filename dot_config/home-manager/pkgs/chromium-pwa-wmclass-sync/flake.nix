{
  description = "A flake for a script to fix Chromium PWA desktop files";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forEachSystem = nixpkgs.lib.genAttrs supportedSystems;

      pwa-fix-pkg = forEachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        pkgs.stdenv.mkDerivation {
          name = "chromium-pwa-wmclass-sync";
          src = ./.;

          buildInputs = [ pkgs.python3 ];

          installPhase = ''
            mkdir -p $out/bin
            cp chromium-pwa-wmclass-sync.py $out/bin/chromium-pwa-wmclass-sync
            chmod +x $out/bin/chromium-pwa-wmclass-sync
            patchShebangs $out/bin/chromium-pwa-wmclass-sync
          '';
        }
      );
    in
    {
      packages = pwa-fix-pkg;

      homeManagerModules.default =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          cfg = config.programs.chromium-pwa-wmclass-sync;
        in
        {
          options.programs.chromium-pwa-wmclass-sync.service.enable =
            lib.mkEnableOption "Chromium PWA desktop file fix service";

          config = lib.mkIf cfg.service.enable {
            home.packages = [ self.packages.${pkgs.system} ];

            systemd.user.services.chromium-pwa-wmclass-sync = {
              Unit = {
                Description = "Fix Chromium PWA desktop files";
              };
              Service = {
                Type = "oneshot";
                ExecStart = "${self.packages.${pkgs.system}}/bin/chromium-pwa-wmclass-sync";
              };
              Install = {
                WantedBy = [ "default.target" ];
              };
            };

            systemd.user.paths.chromium-pwa-wmclass-sync = {
              Unit = {
                Description = "Watch for changes in Chromium PWA desktop files";
              };
              Path = {
                PathChanged = "%h/.local/share/applications/";
              };
              Install = {
                WantedBy = [ "paths.target" ];
              };
            };
          };
        };
    };
}
