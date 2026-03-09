{ lib, pkgs, ... }:

let
  describeToFile = pkgs.writers.writeNuBin "jj-describe-to-file" ''
    # Extract current commit message to a temp file
    def main [tmp_dir: path] {
      let commit_id = (jj log --no-graph -r @ -T commit_id)

      mkdir $tmp_dir
      ls $tmp_dir
      | where type == file and modified < ((date now) - 1hr)
      | each { |it| rm $it.name }

      let tmp_file = $"($tmp_dir)/($commit_id)"

      jj log --no-graph -r @ -T description | save -f $tmp_file

      print $tmp_file
    }
  '';

  describeFromFile = pkgs.writers.writeNuBin "jj-describe-from-file" ''
    # Apply commit message from temp file and clean up
    def main [tmp_file: path] {
      open $tmp_file | jj describe --stdin
      rm $tmp_file
    }
  '';
in
{
  home.packages = [
    describeToFile
    describeFromFile
  ];

  programs.jujutsu.settings.aliases = {
    describe-to-file = [
      "util"
      "exec"
      "--"
      (lib.getExe describeToFile)
    ];

    describe-from-file = [
      "util"
      "exec"
      "--"
      (lib.getExe describeFromFile)
    ];
  };
}
