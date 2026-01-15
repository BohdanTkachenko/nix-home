{
  isWork,
  lib,
  pkgs-unstable,
  ...
}:

let
  ask-claude = pkgs-unstable.writeShellScriptBin "ask-claude" ''
    if [ $# -eq 0 ]; then
      echo "Usage: ask-claude <question>"
      exit 1
    fi

    ${pkgs-unstable.claude-code}/bin/claude --no-session-persistence --model haiku --print "$*" | ${pkgs-unstable.glow}/bin/glow
  '';

  ask-gemini = pkgs-unstable.writeShellScriptBin "ask-gemini" ''
    if [ $# -eq 0 ]; then
      echo "Usage: ask-gemini <question>"
      exit 1
    fi

    ${pkgs-unstable.gemini-cli}/bin/gemini -p "$*" | ${pkgs-unstable.glow}/bin/glow
  '';

  ask = pkgs-unstable.writeShellScriptBin "ask" ''
    exec ${if isWork then ask-gemini else ask-claude}/bin/${if isWork then "ask-gemini" else "ask-claude"} "$@"
  '';
in
{
  home.packages =
    [
      ask
      ask-gemini
    ]
    ++ lib.optionals (!isWork) [
      ask-claude
    ];
}
