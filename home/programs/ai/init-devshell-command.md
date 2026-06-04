Set up or update the Nix devShell for this project with the `.nix-profile` symlink pattern. Follow these steps:

1. **Check for existing `flake.nix`**. If one exists, read it. If not, create one with basic scaffolding. The key pattern uses a `buildEnv` to create a proper profile with `bin/` symlinks, and a `refresh` script to rebuild it:
   ```nix
   {
     description = "<infer from project context>";

     inputs = {
       nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
       flake-utils.url = "github:numtide/flake-utils";
     };

     outputs = { self, nixpkgs, flake-utils }:
       flake-utils.lib.eachDefaultSystem (system:
         let
           pkgs = nixpkgs.legacyPackages.${system};

           devPackages = with pkgs; [
             # Add project-specific packages here
           ];

           refresh = pkgs.writeShellScriptBin "refresh" ''
             nix build .#packages.''${system}.dev-profile --out-link .nix-profile
           '';
         in
         {
           packages.dev-profile = pkgs.buildEnv {
             name = "<project>-dev-profile";
             paths = devPackages ++ [ refresh ];
           };

           devShells.default = pkgs.mkShell {
             packages = devPackages ++ [ refresh ];

             shellHook = ''
               refresh
               export PATH="$PWD/.nix-profile/bin:$PATH"
             '';
           };
         });
   }
   ```

   **Important:** `mkShell` output does not have a `bin/` directory. The `buildEnv` creates the proper directory layout with symlinks. The `refresh` script builds the `dev-profile` package (not the devShell) and links it to `.nix-profile`.

2. **If `flake.nix` already exists but lacks this pattern**, add the `devPackages` list, `refresh` script, `packages.dev-profile` output, and `shellHook`. Preserve all existing packages and configuration.

3. **Create `.envrc`** if it doesn't exist:
   ```
   use flake
   ```

4. **Update `.gitignore`** to include `.nix-profile` and `.direnv` if not already present.

5. **Look at the project** to determine what packages should be in the devShell (e.g., language runtimes, build tools, linters) based on existing config files like `package.json`, `Cargo.toml`, `go.mod`, etc. Ask the user if unsure.

6. **Update the project's `AGENTS.md`** (create if needed) to include a Development Environment section:
   ```markdown
   ## Development Environment

   This project uses a Nix flake with a devShell (`flake.nix`) and direnv (`.envrc`).

   To add a new tool, add it to `packages` in the devShell in `flake.nix` and run `refresh`. Do not use `nix run` or `nix shell` for project tooling — keep everything in the devShell. Use `nix run` only for one-off commands that don't belong in the devShell permanently.
   ```
   If the file already has a Development Environment section, update it to match. Preserve all other existing content.

7. **Remind the user** to run `direnv allow` after the changes.
