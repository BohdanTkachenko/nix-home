{
  description = "A flake for a declarative Flatpak management script";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forEachSystem = nixpkgs.lib.genAttrs supportedSystems;

      manage-flatpaks = forEachSystem (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in pkgs.stdenv.mkDerivation {
          pname = "manage-flatpaks";
          version = "0.1.0";
          src = ./.;

          nativeBuildInputs = [ pkgs.makeWrapper pkgs.jq ];

          installPhase = ''
            install -D -m755 manage-flatpaks.sh $out/bin/manage-flatpaks
            wrapProgram $out/bin/manage-flatpaks \
              --prefix PATH : "/usr/sbin:/usr/bin:${pkgs.jq}/bin"
          '';
        });

    in
    {
      packages = manage-flatpaks;

      homeManagerModules.default = { config, lib, pkgs, ... }:
        let
          cfg = config.programs.manage-flatpaks;
        in
        {
          options.programs.manage-flatpaks = {
            enable = lib.mkEnableOption "the declarative flatpak manager script";

            onUnmanaged = lib.mkOption {
              type = lib.types.enum [ "delete" "log" "ignore" ];
              default = "delete";
              description = ''
                What to do with installed Flatpak packages that are not in the packages list.
                - "delete": Uninstall the unmanaged package (default).
                - "log": Print a warning but do not uninstall.
                - "ignore": Do nothing.
              '';
            };

            repos = lib.mkOption {
              type = lib.types.listOf (lib.types.attrsOf lib.types.str);
              default = [
                { name = "flathub"; location = "https://flathub.org/repo/flathub.flatpakrepo"; }
              ];
              description = "A list of Flatpak repositories to ensure are configured.";
            };

            defaultRepo = lib.mkOption {
              type = lib.types.str;
              default = "flathub";
              description = "The default repository to install packages from.";
            };

            packages = lib.mkOption {
              type = with lib.types; listOf (either str (submodule {
                options = {
                  id = lib.mkOption { type = str; };
                  repo = lib.mkOption { type = str; default = cfg.defaultRepo; };
                  overrides = lib.mkOption {
                    type = with lib.types; attrsOf (either str (listOf str));
                    default = {};
                    description = "Flatpak override settings for the package.";
                    example = ''
                      {
                        filesystem = [ "~/.local/share/applications" ];
                        socket = [ "wayland" ];
                        device = "all";
                      }
                    '';
                  };
                };
              }));
              default = [];
              description = "A list of Flatpak application IDs to install.";
            };
          };

          config = lib.mkIf cfg.enable {
            home.packages = [ manage-flatpaks.${pkgs.system} ];

            home.activation.manage-flatpaks =
              let
                # Normalize the packages list so it's always a list of {id, repo, overrides}
                normalizedPackages = map (p:
                  if lib.isString p then { id = p; repo = cfg.defaultRepo; overrides = {}; }
                  else p // { overrides = p.overrides or {}; }
                ) cfg.packages;

                # Create a string of escaped shell arguments like: "id1 repo1 id2 repo2"
                packageArgs = lib.strings.concatStringsSep " " (map (p:
                  "${lib.escapeShellArg p.id} ${lib.escapeShellArg p.repo}"
                ) normalizedPackages);

                # Create a JSON string for overrides
                overridesJson = builtins.toJSON (lib.listToAttrs (map (p:
                  { name = p.id; value = p.overrides; }
                ) (lib.filter (p: p.overrides != {}) normalizedPackages)));

                # Create a string for the repos
                repoArgs = lib.strings.concatStringsSep " " (map (r:
                  "${lib.escapeShellArg r.name} ${lib.escapeShellArg r.location}"
                ) cfg.repos);

              in
              lib.hm.dag.entryAfter ["writeBoundary"] ''
                ${manage-flatpaks.${pkgs.system}}/bin/manage-flatpaks \
                  --on-unmanaged ${lib.escapeShellArg cfg.onUnmanaged} \
                  --repos ${repoArgs} \
                  --packages ${packageArgs} \
                  --overrides ${lib.escapeShellArg overridesJson}
              '';
          };
        };
    };
}