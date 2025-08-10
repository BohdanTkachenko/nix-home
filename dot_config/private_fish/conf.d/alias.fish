if [ "$(command -v chezmoi)" ]
  abbr -a cm 'chezmoi'
end

if [ "$(command -v micro)" ]
  alias mialias='micro $HOME/.config/fish/conf.d/alias.fish; source $HOME/.config/fish/conf.d/alias.fish'

  abbr -a m      'micro'
  abbr -a vi     'micro'
  abbr -a vim    'micro'
  abbr -a nano   'micro'
  abbr -a ed     'micro'
  abbr -a editor 'micro'
end

if [ "$(command -v eza)" ]
  alias l='eza --icons --group-directories-first -lah'
  alias t='eza --icons --group-directories-first -L 2 -Tlah'
  abbr -a tt 'eza --icons --group-directories-first -L 3 -Tlah'
end

if [ "$(command -v trash)" ]
  abbr -a rm 'trash'
end

if [ "$(command -v bat)" ]
  abbr -a cat 'bat'
end

if [ "$(command -v ug)" ]
  abbr -a grep    'ug'
  abbr -a egrep   'ug -E'
  abbr -a fgrep   'ug -F'
  abbr -a xzgrep  'ug -z'
  abbr -a xzegrep 'ug -zE'
  abbr -a xzfgrep 'ug -zF'
end

if [ "$(command -v git)" ]
  abbr -a gst 'git status'
  abbr -a gd  'git diff'
  abbr -a gp  'git push'
  abbr -a gl  'git pull'
  abbr -a gx  'git log'
  abbr -a gc  'git commit'
  abbr -a ga  'git add'
  abbr -a gaa 'git add -A'
  abbr -a grm 'git rm'
  abbr -a gmv 'git mv'
  abbr -a gcp 'git cp'
  abbr -a gco 'git checkout'
  abbr -a gb  'git branch'
end

if [ "$(command -v kubectl)" ]
  abbr -a k    'kubectl'
  abbr -a kube 'kubectl'
end

if [ "$(command -v tofu)" ]
  abbr -a tf        'tofu'
  abbr -a terraform 'tofu'
end

if [ "$(command -v terragrunt)" ]
  abbr -a tg 'terragrunt'
end
