{ lib, pkgs, ... }:

let
  jjWorkspace = pkgs.writers.writeNuBin "jj-workspace" ''
    # Shared validation: bail unless `jj workspace list` shows a 'default' workspace.
    def ensure-default [] {
      let result = (^jj workspace list | complete)
      if $result.exit_code != 0 {
        let err = ($result.stderr | str trim)
        if ($err | str length) > 0 {
          print -e $err
        }
        exit $result.exit_code
      }
      if not ($result.stdout | lines | any {|line| $line | str starts-with "default:" }) {
        print -e "error: no 'default' workspace found in `jj workspace list`"
        exit 1
      }
    }

    def "main add" [name: string] {
      ensure-default
      ^jj workspace add $"../($name)"
      "gitdir: ../default/.git" | save -f $"../($name)/.git"
    }

    def "main check" [] {
      ensure-default
    }

    def main [] {
      print -e "usage: jj-workspace <add|check> [args]"
      exit 1
    }
  '';
in
{
  home.packages = [
    jjWorkspace
    pkgs.fzf
  ];

  programs.jujutsu.settings.aliases.ws = [
    "util"
    "exec"
    "--"
    (lib.getExe jjWorkspace)
  ];

  programs.fish.functions = {
    ws = ''
      argparse n/new h/help -- $argv
      or return 1

      if set -q _flag_help
        echo "usage: ws [-n] [[<project>/]<workspace>]"
        echo "  ws                          pick interactively"
        echo "  ws <workspace>              switch to <workspace> in current project"
        echo "  ws <project>/               pick workspace within <project>"
        echo "  ws <project>/<workspace>    switch directly"
        echo "  ws -n [<project>/]<ws>      create <ws> then switch"
        return 0
      end

      set -l projects_dir $HOME/Projects
      set -l token $argv[1]

      set -l info (__ws_cwd_info)
      set -l current_proj ""
      if test (count $info) -ge 1
        set current_proj $info[1]
      end

      if set -q _flag_new
        if test -z "$token"
          echo "usage: ws -n [<project>/]<workspace>" >&2
          return 1
        end
        set -l proj
        set -l ws
        if string match -q '*/*' -- $token
          set -l parts (string split -m1 / -- $token)
          set proj $parts[1]
          set ws $parts[2]
        else
          set proj $current_proj
          set ws $token
        end
        if test -z "$proj"
          echo "error: not in a project, and no project specified" >&2
          return 1
        end
        if test -z "$ws"
          echo "error: workspace name required" >&2
          return 1
        end
        set -l default_dir $projects_dir/$proj/default
        if not test -d $default_dir
          echo "error: no default workspace at $default_dir" >&2
          return 1
        end
        pushd $default_dir >/dev/null
        jj ws add $ws
        set -l rc $status
        popd >/dev/null
        test $rc -ne 0; and return $rc
        cd $projects_dir/$proj/$ws
        return 0
      end

      # Switch mode: try direct match; offer to create if the target looks
      # like a missing workspace in an existing multi-ws project; otherwise
      # fall back to interactive pick.
      set -l target (__ws_resolve "$token" "$current_proj")

      if test -z "$target"
        set -l create_proj ""
        set -l create_ws ""

        if string match -q '*/*' -- $token
          set -l parts (string split -m1 / -- $token)
          set -l p $parts[1]
          set -l w $parts[2]
          if test -n "$p"; and test -n "$w"
            if not test -d $projects_dir/$p
              echo "error: project '$p' does not exist" >&2
              return 1
            end
            if not __ws_is_project $projects_dir/$p
              echo "error: '$p' is not a multi-workspace project" >&2
              return 1
            end
            set create_proj $p
            set create_ws $w
          end
        else if test -n "$token"; and test -n "$current_proj"; and __ws_is_project $projects_dir/$current_proj
          # Bare token in a multi-ws project — consider creating unless the
          # token itself names an existing multi-ws project (ambiguous).
          if not __ws_is_project $projects_dir/$token
            set create_proj $current_proj
            set create_ws $token
          end
        end

        if test -n "$create_proj"; and test -n "$create_ws"
          set -l choice (printf 'yes\nno\n' | fzf \
            --prompt='create workspace? ' \
            --header="'$create_ws' in '$create_proj'" \
            --height=~40% --layout=reverse --border=rounded --no-info)
          if test "$choice" != yes
            return 1
          end
          set -l default_dir $projects_dir/$create_proj/default
          pushd $default_dir >/dev/null
          jj ws add $create_ws
          set -l rc $status
          popd >/dev/null
          test $rc -ne 0; and return $rc
          cd $projects_dir/$create_proj/$create_ws
          return 0
        end

        set target (__ws_pick "$token")
        or return 1
      end

      if not test -d "$target"
        echo "error: $target does not exist" >&2
        return 1
      end

      cd $target
    '';

    __ws_cwd_info = ''
      set -l rel (string replace -r "^$HOME/Projects/" "" -- $PWD)
      test "$rel" = "$PWD"; and return
      set -l parts (string split / -- $rel)
      echo $parts[1]
      if test (count $parts) -ge 2
        echo $parts[2]
      end
    '';

    __ws_is_project = ''
      test -e $argv[1]/default/.jj
    '';

    __ws_is_workspace = ''
      test -e $argv[1]/.jj
    '';

    __ws_workspaces_bare = ''
      set -l projects_dir $HOME/Projects
      set -l proj $argv[1]
      test -n "$proj"; or return
      __ws_is_project $projects_dir/$proj; or return
      for bn in (command ls -1 $projects_dir/$proj 2>/dev/null)
        if __ws_is_workspace $projects_dir/$proj/$bn
          echo $bn
        end
      end
    '';

    __ws_projects_list = ''
      set -l projects_dir $HOME/Projects
      test -d $projects_dir; or return
      for bn in (command ls -1 $projects_dir 2>/dev/null)
        if __ws_is_project $projects_dir/$bn
          echo $bn
        end
      end
      return 0
    '';

    __ws_singles_list = ''
      set -l projects_dir $HOME/Projects
      test -d $projects_dir; or return
      for bn in (command ls -1 $projects_dir 2>/dev/null)
        test -d $projects_dir/$bn; or continue
        if not __ws_is_project $projects_dir/$bn
          echo $bn
        end
      end
      return 0
    '';

    __ws_candidates = ''
      set -l info (__ws_cwd_info)
      set -l current_proj ""
      set -l current_ws ""
      if test (count $info) -ge 1
        set current_proj $info[1]
      end
      if test (count $info) -ge 2
        set current_ws $info[2]
      end

      # 1. Current project's bare workspaces (excluding the one we're in).
      if test -n "$current_proj"
        for ws in (__ws_workspaces_bare $current_proj)
          if test "$ws" != "$current_ws"
            echo $ws
          end
        end
      end

      # 2. Multi-workspace projects as "proj/".
      for proj in (__ws_projects_list)
        if test "$proj" != "$current_proj"
          echo "$proj/"
        end
      end

      # 3. Single-dir projects (bare folders under ~/Projects that aren't
      # multi-workspace layouts) — "project+workspace in one".
      for dir in (__ws_singles_list)
        if test "$dir" != "$current_proj"
          echo $dir
        end
      end
      return 0
    '';

    __ws_resolve = ''
      set -l token $argv[1]
      set -l current_proj $argv[2]
      set -l projects_dir $HOME/Projects
      test -n "$token"; or return
      if string match -q '*/*' -- $token
        set -l parts (string split -m1 / -- $token)
        set -l proj $parts[1]
        set -l ws $parts[2]
        test -n "$ws"; or return
        set -l target $projects_dir/$proj/$ws
        if test -d $target
          echo $target
        end
        return
      end
      # Bare token — try in order:
      # 1. Workspace within current multi-workspace project
      if test -n "$current_proj"
        set -l target $projects_dir/$current_proj/$token
        if test -d $target
          echo $target
          return
        end
      end
      # 2. Single-dir project (folder directly under ~/Projects, not a
      #    multi-workspace layout — switching to root is meaningful)
      set -l target $projects_dir/$token
      if test -d $target
        if __ws_is_project $target
          # Multi-workspace project root: no direct match; picker drills in.
          return
        end
        echo $target
      end
    '';

    __ws_pick = ''
      set -l query $argv[1]
      set -l candidates (__ws_candidates)
      if test (count $candidates) -eq 0
        echo "error: no workspaces or projects found" >&2
        return 1
      end
      set -l picked (printf '%s\n' $candidates | fzf --query=$query --select-1 --exit-0 --prompt='ws> ')
      set -l rc $status
      if test $rc -ne 0
        if test $rc -eq 1; and test -n "$query"
          echo "error: no match for '$query'" >&2
        end
        return 1
      end

      if string match -q '*/' -- $picked
        # Drill into project: second picker over its workspaces.
        set -l proj (string replace -r '/$' "" -- $picked)
        set -l sub (__ws_workspaces_bare $proj)
        if test (count $sub) -eq 0
          echo "error: no workspaces in $proj" >&2
          return 1
        end
        set -l picked2 (printf '%s\n' $sub | fzf --select-1 --exit-0 --prompt="$proj/> ")
        or return 1
        echo $HOME/Projects/$proj/$picked2
        return 0
      end

      # Bare candidate — could be a workspace in current project or a
      # single-dir project. Resolve via the same logic as direct matches.
      set -l info (__ws_cwd_info)
      set -l current_proj ""
      if test (count $info) -ge 1
        set current_proj $info[1]
      end
      set -l target (__ws_resolve "$picked" "$current_proj")
      if test -z "$target"
        echo "error: could not resolve '$picked'" >&2
        return 1
      end
      echo $target
    '';

    __ws_complete = ''
      set -l token (commandline -ct)
      if string match -q '*/*' -- $token
        set -l proj (string split -m1 / -- $token)[1]
        test -n "$proj"; or return
        for ws in (__ws_workspaces_bare $proj)
          printf '%s/%s\tworkspace\n' $proj $ws
        end
        return 0
      end

      set -l info (__ws_cwd_info)
      set -l current_proj ""
      if test (count $info) -ge 1
        set current_proj $info[1]
      end

      for c in (__ws_candidates)
        if string match -q '*/' -- $c
          printf '%s\tproject\n' $c
        else if test -n "$current_proj"; and __ws_is_workspace $HOME/Projects/$current_proj/$c
          printf '%s\tworkspace\n' $c
        else
          echo $c
        end
      end
      return 0
    '';
  };

  xdg.configFile."fish/completions/ws.fish".text = ''
    complete -c ws -s n -l new -d 'create workspace before switching'
    complete -c ws -s h -l help -d 'show usage'
    complete -c ws -f -k -a '(__ws_complete)'
  '';
}
