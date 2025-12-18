{ pkgs, ... }:
{
  programs.bash.initExtra = ''
    dotfiles() {
      if [[ "$1" == "cd" ]]; then
        cd "$HOME/.config/nix"
      else
        if [ -e /etc/NIXOS ]; then
          nix-shell -p gnumake --run "make -C $HOME/.config/nix ''$@"
        else
          make -C "$HOME/.config/nix" "$@"
        fi
      fi
    }
  '';

  programs.fish.functions = {
    dotfiles = ''
      if test "$argv[1]" = "cd"
        cd "$HOME/.config/nix"
      else
        if test -e /etc/NIXOS
          nix-shell -p gnumake --run "make -C $HOME/.config/nix $argv"
        else
          make -C "$HOME/.config/nix" $argv
        end
      end
    '';
  };
}
