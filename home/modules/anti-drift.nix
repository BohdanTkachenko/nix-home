{ config, lib, pkgs, ... }:
let
  cfg = config.anti-drift;

  jq = lib.getExe pkgs.jq;
  diff = lib.getExe' pkgs.diffutils "diff";

  fileEntries = lib.attrsToList cfg.files;

  perFileScript = lib.concatMapStringsSep "\n" (entry:
    let
      path = entry.name;
      opts = entry.value;
      target = "$HOME/${path}";
      baseline = "${target}.nix-baseline";
      normalize = if opts.json then
        ''$jq --sort-keys . "$1" 2>/dev/null || cat "$1"''
      else
        ''cat "$1"'';
    in ''
      # --- ${path} ---
      normalize_${builtins.replaceStrings [ "." "-" "/" ] [ "_" "_" "_" ] path}() {
        ${normalize}
      }

      run mkdir -p "$(dirname "${target}")"

      # Detect drift
      if [ -f "${target}" ] && [ -e "${baseline}" ]; then
        normalizedBaseline=$(normalize_${builtins.replaceStrings [ "." "-" "/" ] [ "_" "_" "_" ] path} "${baseline}")
        normalizedCurrent=$(normalize_${builtins.replaceStrings [ "." "-" "/" ] [ "_" "_" "_" ] path} "${target}")

        if [ "$normalizedBaseline" != "$normalizedCurrent" ]; then
          driftedFiles+=("${path}")
          $diff -u \
            <(echo "$normalizedBaseline") \
            <(echo "$normalizedCurrent") \
            --label "nix-managed" --label "current" >&2 || true
        fi
      fi

      # Copy new version and update baseline
      run rm -f "${target}" "${baseline}"
      run cp "${opts.source}" "${target}"
      run chmod 644 "${target}"
      run ln -s "${opts.source}" "${baseline}"
    ''
  ) fileEntries;
in
{
  options.anti-drift.files = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      options = {
        source = lib.mkOption {
          type = lib.types.path;
          description = "Nix store path to copy from";
        };
        json = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Normalize with jq --sort-keys before diffing";
        };
      };
    });
    default = { };
    description = "Files to manage with mutable copy and drift detection";
  };

  config = lib.mkIf (cfg.files != { }) {
    home.file = lib.mapAttrs' (path: _opts:
      lib.nameValuePair path { enable = false; }
    ) cfg.files;

    home.activation.antiDrift = lib.hm.dag.entryAfter [ "reloadSystemd" ] ''
      jq="${jq}"
      diff="${diff}"

      driftedFiles=()

      ${perFileScript}

      if [ ''${#driftedFiles[@]} -gt 0 ]; then
        noteEcho ""
        noteEcho "anti-drift: the following files were modified outside of Nix:"
        for f in "''${driftedFiles[@]}"; do
          noteEcho "  ~/$f"
        done
        noteEcho ""
        noteEcho "To preserve changes, add them to your Nix configuration before rebuilding."
        exit 1
      fi
    '';
  };
}
