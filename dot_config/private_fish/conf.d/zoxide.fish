if status is-interactive
    if [ "$(command -v zoxide)" ]
      eval "$(zoxide init fish)"
      abbr -a cd 'z'
    end
end
