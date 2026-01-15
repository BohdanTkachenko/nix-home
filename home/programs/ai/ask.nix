{
  isWork,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:

let
  mkAskAiScript =
    {
      name,
      exe,
      args,
    }:
    pkgs-unstable.writeShellScriptBin name ''
      TOOL="${exe}"
      STDERR_LOG="/tmp/${name}.error.log"
      DEFAULT_INSTRUCTION="Help me understand this input."
      ARGS=(${builtins.concatStringsSep " " (map (a: "'${a}'") args)})

      if [ $# -gt 0 ]; then
        instruction="$*"
      else
        instruction="''${DEFAULT_INSTRUCTION}"
      fi

      generate_input() {
        printf "## Request\n%s\n\n" "''${instruction}"

        if [ ! -t 0 ]; then
          printf "%b" "---\n\n## Input Data\n"
          cat -
        fi
      }

      if [ $# -eq 0 ] && [ -t 0 ]; then
        echo "Usage: ${name} [prompt]"
        echo "       ${name} [custom instruction] < stdin"
        echo "       ${name} < stdin"
        exit 1
      fi

      generate_input \
      | "$TOOL" "''${ARGS[@]}" 2> "$STDERR_LOG" \
      | "${pkgs-unstable.glow}/bin/glow"
    '';

  ask-gemini = mkAskAiScript {
    name = "ask-gemini";
    exe = "${pkgs.gemini-cli}/bin/gemini";
    args = [
      "--extensions"
      ""
      "--allowed-mcp-server-names"
      ""
    ];
  };

  ask-claude = mkAskAiScript {
    name = "ask-claude";
    exe = "${pkgs-unstable.claude-code}/bin/claude";
    args = [
      "--no-session-persistence"
      "--model"
      "haiku"
      "--print"
      "-"
    ];
  };

  ask =
    let
      targetPkg = if isWork then ask-gemini else ask-claude;
      targetBin = if isWork then "ask-gemini" else "ask-claude";
    in
    pkgs.runCommand "ask" { } ''
      mkdir -p $out/bin
      ln -s ${targetPkg}/bin/${targetBin} $out/bin/ask
    '';
in
{
  home.packages = [
    ask
    ask-gemini
  ]
  ++ lib.optionals (!isWork) [
    ask-claude
  ];
}
