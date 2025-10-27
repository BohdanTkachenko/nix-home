{ pkgs, ... }:

{
  programs.bash = {
    enable = true;

    initExtra = ''
      SSH_ENV="$HOME/.ssh/agent.env"

      function start_agent {
        /usr/bin/ssh-agent -s > "$SSH_ENV"
        chmod 600 "$SSH_ENV"
        . "$SSH_ENV" > /dev/null
      }

      if [ -f "$SSH_ENV" ]; then
        . "$SSH_ENV" > /dev/null

        if [ ! -S "$SSH_AUTH_SOCK" ] || ! kill -0 "$SSH_AGENT_PID" 2>/dev/null; then
          start_agent
        fi
      else
        start_agent
      fi

      if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
      then
        shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
        exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
      fi
    '';
  };
}
