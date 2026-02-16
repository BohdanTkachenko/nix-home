# Extract current commit message to a temp file
def "main write" [] {
  let commit_id = (jj log --no-graph -r @ -T commit_id)

  let tmp_dir = ([(jj root), ".jj", "tmp"] | path join)
  mkdir $tmp_dir
  ls $tmp_dir
  | where type == file and modified < ((date now) - 1hr)
  | each { |it| rm $it.name }

  let tmp_file = $"($tmp_dir)/jj-commit-message.($commit_id)"

  jj log --no-graph -r @ -T description | save -f $tmp_file

  print $tmp_file
}

# Apply commit message from temp file and clean up
def "main apply" [tmp_file: path] {
  open $tmp_file | jj describe --stdin
  rm $tmp_file
}

def main [] {
  print "Usage: jj-commit-msg <write|apply>"
  print "  write         - Extract current commit message to temp file"
  print "  apply <file>  - Apply commit message from file and delete it"
}
