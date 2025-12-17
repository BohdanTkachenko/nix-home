{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  isWorkLaptop ? false,
  isWorkPC ? false,
  ...
}:
let
  geminiPkg =
    if isWorkPC then
      (pkgs.writeScriptBin "gemini" ''
        #!/bin/sh
        /google/bin/releases/gemini-cli/tools/gemini --gfg "$@"
      '')
    else if isWorkLaptop then
      (pkgs.writeScriptBin "gemini" ''
        #!/bin/sh
        "${pkgs-unstable.gemini-cli}/bin/gemini --proxy=false "$@"
      '')
    else
      pkgs-unstable.gemini-cli;
in
{
  programs.gemini-cli = {
    enable = true;
    package = geminiPkg;

    commands = {
      commit = {
        description = "Generates a Jujutsu commit message based on diff.";
        prompt = ''
          ## Context

          ### List of all changes made:

          ```
          !{jj status}
          ```

          ### Recent commits history:

          ```
          !{jj log -r "present(p4base)..@" --no-graph -n 10 -T builtin_log_detailed}
          ```

          ### Full diff:

          ```diff
          !{jj diff}
          ```
          ## Task

          Based on the changes above, create a single atomic Jujutsu commit
          with a descriptive message. Utilize Conventional Commits only if
          previous commits use them, otherwise do not use Conventional Commits.

          This is intended as a low effort way for the user to commit, so avoid
          asking user questions, unless absolutely necessary. User may ask you
          to correct the message as needed.

          Run the following two commands with the new commit message:

          ```sh
          jj describe -m "<provide your generated commit message here>" && jj new
          ```
        '';
      };
    };
  };

  home.file.".gemini/settings.json" = lib.mkIf (!isWorkPC) {
    source = lib.mkForce (
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nix/home/programs/gemini-cli/settings.json"
    );
  };
}
