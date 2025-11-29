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
    } // (
      let
        letters = ["a" "b" "c" "d" "e" "f" "g" "h" "i" "j" "k" "l" "m" "n" "o" "p" "q" "r" "s" "t" "u" "v" "w" "x" "y" "z"];
        
        # 1-letter aliases: jja -> jj a
        oneLetterAliases = map (first: {
          name = "jj${first}";
          value = "jj ${first}";
        }) letters;
        
        # 2-letter aliases: jjab -> jj ab  
        twoLetterAliases = builtins.concatLists (map (first:
          map (second: {
            name = "jj${first}${second}";
            value = "jj ${first}${second}";
          }) letters
        ) letters);
        
        # 3-letter aliases: jjabc -> jj abc
        threeLetterAliases = builtins.concatLists (builtins.concatLists (map (first:
          map (second:
            map (third: {
              name = "jj${first}${second}${third}";
              value = "jj ${first}${second}${third}";
            }) letters
          ) letters
        ) letters));
      in
        builtins.listToAttrs (oneLetterAliases ++ twoLetterAliases ++ threeLetterAliases)
    );

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

    interactiveShellInit = ''
      if not set -q fish_configured
        set -U fish_greeting

        set -U fish_color_command green --bold
        set -U fish_color_end blue

        set -U fish_configured
      end
    '';
  };
}
