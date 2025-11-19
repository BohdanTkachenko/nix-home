{ lib, ... }:
{
  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    settings = {
      format = lib.concatStrings [
        "$nix_shell"
        "$username"
        "$hostname"
        "$localip"
        "$shlvl"
        "$directory"
        "\${custom.jj}"
        "$git_branch"
        "$git_commit"
        "$git_state"
        "$git_metrics"
        "$git_status"
        "$hg_branch"
        "$hg_state"
        "$sudo"
        "$os"
        "$shell"
        "$character"
      ];

      right_format = lib.concatStrings [
        "$kubernetes"
        "$docker_context"
        "$package"
        "$c"
        "$cmake"
        "$dart"
        "$golang"
        "$java"
        "$kotlin"
        "$nodejs"
        "$perl"
        "$python"
        "$ruby"
        "$rust"
        "$terraform"
        "$conda"
        "$memory_usage"
        "$gcloud"
        "$direnv"
        "$battery"
        "$time"
        "$status"
        "$container"
      ];

      custom.jj = {
        description = "The current jj status";
        when = "jj --ignore-working-copy root";
        symbol = " ";
        command = ''
          jj log --revisions @ --no-graph --ignore-working-copy --color always --limit 1 --template '
            separate(" ",
              change_id.shortest(4),
              bookmarks,
              "|",
              concat(
                if(conflict, "💥"),
                if(divergent, "🚧"),
                if(hidden, "👻"),
                if(immutable, "🔒"),
              ),
              raw_escape_sequence("\x1b[1;32m") ++ if(empty, "(empty)"),
              raw_escape_sequence("\x1b[1;32m") ++ coalesce(
                truncate_end(29, description.first_line(), "…"),
                "(no description set)",
              ) ++ raw_escape_sequence("\x1b[0m"),
            )
          '
        '';
      };

      custom.jjstate = {
        when = "jj --ignore-working-copy root";
        command = ''
          jj log -r@ -n1 --ignore-working-copy --no-graph -T "" --stat | tail -n1 | sd "(\d+) files? changed, (\d+) insertions?\(\+\), (\d+) deletions?\(-\)" ' $\{1}m $\2}+ $\{3}-' | sd " 0." ""
        '';
      };

      git_status.disabled = true;
      custom.git_status = {
        when = "! jj --ignore-working-copy root";
        command = "starship module git_status";
        style = ""; # This disables the default "(bold green)" style
        description = "Only show git_status if we're not in a jj repo";
      };

      git_commit.disabled = true;
      custom.git_commit = {
        when = "! jj --ignore-working-copy root";
        command = "starship module git_commit";
        style = "";
        description = "Only show git_commit if we're not in a jj repo";
      };

      git_metrics.disabled = true;
      custom.git_metrics = {
        when = "! jj --ignore-working-copy root";
        command = "starship module git_metrics";
        description = "Only show git_metrics if we're not in a jj repo";
        style = "";
      };

      git_branch.disabled = true;
      custom.git_branch = {
        when = "! jj --ignore-working-copy root";
        command = "starship module git_branch";
        description = "Only show git_branch if we're not in a jj repo";
        style = "";
      };

      # Nerd Font Icons
      c.symbol = " ";
      cmake.symbol = " ";
      conda.symbol = " ";
      cpp.symbol = " ";
      dart.symbol = " ";
      directory.read_only = " 󰌾";
      docker_context.symbol = " ";
      gcloud.symbol = " ";
      git_branch.symbol = " ";
      git_commit.tag_symbol = "  ";
      golang.symbol = " ";
      hg_branch.symbol = " ";
      hostname.ssh_symbol = " ";
      java.symbol = " ";
      kotlin.symbol = " ";
      memory_usage.symbol = "󰍛 ";
      meson.symbol = "󰔷 ";
      nix_shell.symbol = " ";
      nodejs.symbol = " ";
      os.symbols.Android = " ";
      os.symbols.Arch = " ";
      os.symbols.Debian = " ";
      os.symbols.Fedora = " ";
      os.symbols.Kali = " ";
      os.symbols.Linux = " ";
      os.symbols.NixOS = " ";
      os.symbols.Raspbian = " ";
      os.symbols.Ubuntu = " ";
      os.symbols.Unknown = " ";
      package.symbol = "󰏗 ";
      perl.symbol = " ";
      python.symbol = " ";
      ruby.symbol = " ";
      rust.symbol = "󱘗 ";
      scala.symbol = " ";
      status.symbol = " ";
      swift.symbol = " ";
    };
  };
}
