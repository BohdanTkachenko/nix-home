# Tests for ask CLI tools
{ self, lib }:
let
  personalPackages = self.nixosConfigurations.nyancat.config.home-manager.users.dan.home.packages;
  workPackages = self.homeConfigurations."bohdant@dan.nyc.corp.google.com".config.home.packages;

  hasPackage = packages: name: lib.any (pkg: pkg.pname or pkg.name or "" == name) packages;

  getPackageScript = packages: name:
    let
      pkg = lib.findFirst (p: p.pname or p.name or "" == name) null packages;
    in
    if pkg != null then builtins.readFile (lib.getExe pkg) else "";
in
{
  ask-personal-has-ask-claude = {
    expr = hasPackage personalPackages "ask-claude";
    expected = true;
  };

  ask-personal-has-ask-gemini = {
    expr = hasPackage personalPackages "ask-gemini";
    expected = true;
  };

  ask-personal-aliases-to-claude = {
    expr = lib.hasInfix "ask-claude" (getPackageScript personalPackages "ask");
    expected = true;
  };

  ask-work-no-ask-claude = {
    expr = hasPackage workPackages "ask-claude";
    expected = false;
  };

  ask-work-has-ask-gemini = {
    expr = hasPackage workPackages "ask-gemini";
    expected = true;
  };

  ask-work-aliases-to-gemini = {
    expr = lib.hasInfix "ask-gemini" (getPackageScript workPackages "ask");
    expected = true;
  };
}
