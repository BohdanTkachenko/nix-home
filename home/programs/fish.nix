{
  isWork,
  lib,
  pkgs,
  ...
}:

{
  programs.fish = {
    enable = true;

    shellAliases = {
      cat = "bat --no-pager --plain";
      less = "bat --plain";

      l = "eza --extended --icons --hyperlink --group-directories-first -lah";
      t = "l --ignore-glob '.git|.jj' -TL 2";

      rm = "trash";

      grep = "ug";
      egrep = "ug -E";
      fgrep = "ug -F";
      xzgrep = "ug -z";
      xzegrep = "ug -zE";
      xzfgrep = "ug -zF";
    };

    shellAbbrs = {
      tt = "t -L 5";
      ta = "t --absolute=on -L 5";
    };

    plugins = with pkgs.fishPlugins; [
      {
        name = "sponge";
        inherit (z) src;
      }

      {
        name = "z";
        inherit (z) src;
      }
    ];

    interactiveShellInit = lib.mkMerge [
      ''
        if not set -q fish_configured
          set -U fish_greeting

          set -U fish_color_command green --bold
          set -U fish_color_end blue

          set -U fish_configured
        end

        if set -q SSH_CONNECTION && not set -q SSH_AUTH_SOCK
          echo (set_color yellow)"Warning: SSH_AUTH_SOCK is not set. SSH agent forwarding may not be working."(set_color normal)
        end
      ''

      (lib.mkIf isWork ''
        source_google_fish_package autogcert
        source_google_fish_package buildfix
        source_google_fish_package citc_prompt
        source_google_fish_package hb
        source_google_fish_package pastebin
      '')
    ];
  };
}
