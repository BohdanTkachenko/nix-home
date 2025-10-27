{ pkgs, ... }:

{
  programs.fish = {
    enable = true;

    shellAliases = {
      hm = "make -C ~/.config/home-manager";
      hmcd = "cd ~/.config/home-manager";

      l = "eza --icons --group-directories-first -lah";
      t = "eza --icons --group-directories-first -L 2 -Tlah";
    };

    shellAbbrs = {
      m = "micro";
      vi = "micro";
      vim = "micro";
      nano = "micro";
      ed = "micro";
      editor = "micro";

      tt = "eza --icons --group-directories-first -L 3 -Tlah";

      rm = "trash";
      cat = "bat";

      grep = "ug";
      egrep = "ug -E";
      fgrep = "ug -F";
      xzgrep = "ug -z";
      xzegrep = "ug -zE";
      xzfgrep = "ug -zF";

      gst = "git status";
      gd = "git diff";
      gp = "git push";
      gl = "git pull";
      gx = "git log";
      gc = "git commit";
      ga = "git add";
      gaa = "git add -A";
      grm = "git rm";
      gmv = "git mv";
      gcp = "git cp";
      gco = "git checkout";
      gb = "git branch";

      k = "kubectl";
      kube = "kubectl";

      tf = "tofu";
      terraform = "tofu";
      tg = "terragrunt";
    };

    plugins = with pkgs.fishPlugins; [
      {
        name = "tide";
        inherit (tide) src;
      }

      {
        name = "sponge";
        inherit (z) src;
      }

      {
        name = "z";
        inherit (z) src;
      }
    ];

    interactiveShellInit = ''
      if not set -q fish_configured
        set -U fish_greeting

        set -U fish_color_command green --bold
        set -U fish_color_end blue

        tide configure --auto \
          --style=Lean \
          --prompt_colors='True color' \
          --show_time='24-hour format' \
          --lean_prompt_height='One line' \
          --prompt_spacing=Compact \
          --icons='Many icons' \
          --transient=Yes
        tide reload

        set -U fish_configured
      end
    '';
  };
}
