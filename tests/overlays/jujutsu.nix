# Tests for jujutsu overlay
{ self, lib }:
let
  # Access pkgs through the configs to get overlayed packages
  personalPkgs = self.nixosConfigurations.nyancat.pkgs;
  workPkgs = self.homeConfigurations."bohdant@dan.nyc.corp.google.com".pkgs;

  # Check if path contains "jujutsu" (real package) vs just "jj" (wrapper)
  isRealJujutsuPackage = pkg: lib.hasInfix "jujutsu" (lib.getExe pkg);
in
{
  jujutsu-personal-uses-unstable = {
    expr = isRealJujutsuPackage personalPkgs.jujutsu;
    expected = true;
    description = "Personal config should use real jujutsu package from unstable";
  };

  jujutsu-work-is-wrapper = {
    expr = isRealJujutsuPackage workPkgs.jujutsu;
    expected = false;
    description = "Work config should use jj wrapper script (not real jujutsu)";
  };

  jujutsu-work-calls-system-binary = {
    expr = lib.hasInfix "/usr/bin/jj" (builtins.readFile (lib.getExe workPkgs.jujutsu));
    expected = true;
    description = "Work jujutsu wrapper should call /usr/bin/jj";
  };
}
