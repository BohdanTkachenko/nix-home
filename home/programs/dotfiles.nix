{ pkgs, ... }:
{
  programs.bash.initExtra = ''
    dotfiles() {
      if [[ "$1" == "cd" ]]; then
        cd "$HOME/Projects/nix-home"
      else
        if [ -e /etc/NIXOS ]; then
          nix-shell -p gnumake --run "make -C $HOME/Projects/nix-home ''$@"
        else
          make -C "$HOME/Projects/nix-home" "$@"
        fi
      fi
    }
  '';

  programs.fish.functions = {
    dotfiles = ''
      if test "$argv[1]" = "cd"
        cd "$HOME/Projects/nix-home"
      else
        if test -e /etc/NIXOS
          nix-shell -p gnumake --run "make -C $HOME/Projects/nix-home $argv"
        else
          make -C "$HOME/Projects/nix-home" $argv
        end
      end
    '';
  };
}
