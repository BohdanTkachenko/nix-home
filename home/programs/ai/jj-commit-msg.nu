# Extract current commit message to a temp file
def "main write" [tmp_dir: path] {
  let commit_id = (jj log --no-graph -r @ -T commit_id)

  mkdir $tmp_dir
  ls $tmp_dir
  | where type == file and modified < ((date now) - 1hr)
  | each { |it| rm $it.name }

  let tmp_file = $"($tmp_dir)/($commit_id)"

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
  print "  write <dir>   - Extract current commit message to a file"
  print "  apply <file>  - Apply commit message from file and delete it"
}
