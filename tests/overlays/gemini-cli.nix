# Tests for gemini-cli overlay
{ self, lib }:
let
  # Access pkgs through the configs to get overlayed packages
  personalPkgs = self.nixosConfigurations.nyancat.pkgs;
  workPcPkgs = self.homeConfigurations."bohdant@dan.nyc.corp.google.com".pkgs;
  workLaptopPkgs = self.homeConfigurations."bohdant@bohdant.roam.corp.google.com".pkgs;

  # Real gemini-cli package path contains "gemini-cli"
  isRealGeminiPackage = pkg: lib.hasInfix "gemini-cli" (lib.getExe pkg);
in
{
  gemini-personal-uses-unstable = {
    expr = isRealGeminiPackage personalPkgs.gemini-cli;
    expected = true;
    description = "Personal config should use real gemini-cli package from unstable";
  };

  gemini-work-pc-is-wrapper = {
    expr = isRealGeminiPackage workPcPkgs.gemini-cli;
    expected = false;
    description = "Work PC should use gemini wrapper (not real package)";
  };

  gemini-work-pc-has-gfg-flag = {
    expr = lib.hasInfix "--gfg" (builtins.readFile (lib.getExe workPcPkgs.gemini-cli));
    expected = true;
    description = "Work PC gemini wrapper should include --gfg flag";
  };

  gemini-work-laptop-has-proxy-flag = {
    expr = lib.hasInfix "--proxy=false" (builtins.readFile (lib.getExe workLaptopPkgs.gemini-cli));
    expected = true;
    description = "Work laptop gemini wrapper should include --proxy=false flag";
  };
}
