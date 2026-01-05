# Tests for google-chrome overlay
{ self, lib }:
let
  # Access pkgs through the configs to get overlayed packages
  personalPkgs = self.nixosConfigurations.nyancat.pkgs;
  workPkgs = self.homeConfigurations."bohdant@dan.nyc.corp.google.com".pkgs;

  # Real chrome package path contains "google-chrome-<version>"
  isRealChromePackage = pkg: lib.hasInfix "google-chrome-1" (lib.getExe pkg);
in
{
  chrome-personal-is-real-package = {
    expr = isRealChromePackage personalPkgs.google-chrome;
    expected = true;
    description = "Personal config should use real google-chrome package";
  };

  chrome-work-is-wrapper = {
    expr = isRealChromePackage workPkgs.google-chrome;
    expected = false;
    description = "Work config should use chrome wrapper (not real package)";
  };

  chrome-work-wrapper-has-dark-mode-flag = {
    expr = lib.hasInfix "--force-dark-mode" (builtins.readFile (lib.getExe' workPkgs.google-chrome "google-chrome-stable"));
    expected = true;
    description = "Work chrome wrapper should include --force-dark-mode flag";
  };

  chrome-work-calls-system-binary = {
    expr = lib.hasInfix "/usr/bin/google-chrome-stable" (builtins.readFile (lib.getExe' workPkgs.google-chrome "google-chrome-stable"));
    expected = true;
    description = "Work chrome wrapper should call system binary";
  };
}
