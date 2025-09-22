{ pkgs, ... }:

{
  programs.bash = {
    enable = true;

    profileExtra = ''
    # Source the system-wide Nix profile if it exists
    if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix.sh ]; then
      . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
    fi
    '';

    initExtra = ''
    if [[ $(ps --no-header --pid=''${PPID} --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} && ( ''${SHLVL} == 1 || -n "''${DISTROBOX_ENTER_PATH}" ) ]]
    then
      shopt -q login_shell && LOGIN_OPTION="--login" || LOGIN_OPTION=""
      export SHELL=/usr/sbin/fish
      exec fish ''$LOGIN_OPTION
    fi
    '';
  };
}