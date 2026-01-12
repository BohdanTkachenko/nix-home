# Test that the google-chrome overlay correctly configures systemd units for work profile.
# Used by: nix flake check
{ pkgs ? import <nixpkgs> { }, lib ? pkgs.lib, runCommand ? pkgs.runCommand, ... }:
let
  # Mock browser-previews packages
  mockBrowserPreviews = {
    google-chrome-beta = pkgs.writeScriptBin "google-chrome-beta" "";
    google-chrome-dev = pkgs.writeScriptBin "google-chrome-dev" "";
  };

  # Evaluate the module with isWork = true
  evaluatedWork = lib.evalModules {
    modules = [
      # Minimal home-manager compatible module interface
      ({ ... }: {
        options = {
          nixpkgs.overlays = lib.mkOption {
            type = lib.types.listOf lib.types.unspecified;
            default = [ ];
          };
          systemd.user.services = lib.mkOption {
            type = lib.types.attrsOf lib.types.anything;
            default = { };
          };
          systemd.user.paths = lib.mkOption {
            type = lib.types.attrsOf lib.types.anything;
            default = { };
          };
        };
      })
      # The module under test
      (import ../overlays/google-chrome.nix)
    ];
    specialArgs = {
      inherit pkgs lib;
      browser-previews-pkgs = mockBrowserPreviews;
      isWork = true;
    };
  };

  # Evaluate the module with isWork = false
  evaluatedPersonal = lib.evalModules {
    modules = [
      ({ ... }: {
        options = {
          nixpkgs.overlays = lib.mkOption {
            type = lib.types.listOf lib.types.unspecified;
            default = [ ];
          };
          systemd.user.services = lib.mkOption {
            type = lib.types.attrsOf lib.types.anything;
            default = { };
          };
          systemd.user.paths = lib.mkOption {
            type = lib.types.attrsOf lib.types.anything;
            default = { };
          };
        };
      })
      (import ../overlays/google-chrome.nix)
    ];
    specialArgs = {
      inherit pkgs lib;
      browser-previews-pkgs = mockBrowserPreviews;
      isWork = false;
    };
  };

  workConfig = evaluatedWork.config;
  personalConfig = evaluatedPersonal.config;

  # Test assertions - each returns { name, passed, msg }
  tests = [
    {
      name = "Work profile has google-chrome-stable service";
      passed = workConfig.systemd.user.services ? "fix-google-chrome-stable-autostart";
    }
    {
      name = "Work profile has google-chrome-beta service";
      passed = workConfig.systemd.user.services ? "fix-google-chrome-beta-autostart";
    }
    {
      name = "Work profile has google-chrome-unstable service";
      passed = workConfig.systemd.user.services ? "fix-google-chrome-unstable-autostart";
    }
    {
      name = "Work profile has google-chrome-stable path";
      passed = workConfig.systemd.user.paths ? "fix-google-chrome-stable-autostart";
    }
    {
      name = "Work profile has google-chrome-beta path";
      passed = workConfig.systemd.user.paths ? "fix-google-chrome-beta-autostart";
    }
    {
      name = "Work profile has google-chrome-unstable path";
      passed = workConfig.systemd.user.paths ? "fix-google-chrome-unstable-autostart";
    }
    {
      name = "Path unit watches ~/.config/autostart/";
      passed =
        let path = workConfig.systemd.user.paths."fix-google-chrome-stable-autostart";
        in (path.Path.PathChanged or null) == "%h/.config/autostart/";
    }
    {
      name = "Path unit is wanted by paths.target";
      passed =
        let path = workConfig.systemd.user.paths."fix-google-chrome-stable-autostart";
        in builtins.elem "paths.target" (path.Install.WantedBy or [ ]);
    }
    {
      name = "Service is oneshot type";
      passed =
        let service = workConfig.systemd.user.services."fix-google-chrome-stable-autostart";
        in (service.Service.Type or null) == "oneshot";
    }
    {
      name = "Service ExecStart contains fix-chrome-autostart";
      passed =
        let service = workConfig.systemd.user.services."fix-google-chrome-stable-autostart";
        in lib.hasInfix "fix-chrome-autostart" (service.Service.ExecStart or "");
    }
    {
      name = "Personal profile has no Chrome autostart services";
      passed = personalConfig.systemd.user.services == { };
    }
    {
      name = "Personal profile has no Chrome autostart paths";
      passed = personalConfig.systemd.user.paths == { };
    }
    {
      name = "Overlay is defined for work profile";
      passed = (builtins.length workConfig.nixpkgs.overlays) == 1;
    }
    {
      name = "Overlay is defined for personal profile";
      passed = (builtins.length personalConfig.nixpkgs.overlays) == 1;
    }
  ];

  failedTests = builtins.filter (t: !t.passed) tests;
  allPassed = failedTests == [ ];

  # Generate test report
  testReport = lib.concatMapStringsSep "\n" (t:
    if t.passed then "PASS: ${t.name}" else "FAIL: ${t.name}"
  ) tests;

  failedReport = lib.concatMapStringsSep "\n" (t: "FAIL: ${t.name}") failedTests;
in
runCommand "test-google-chrome-overlay" { } ''
  echo "Running google-chrome overlay tests..."
  echo ""
  cat <<'EOF'
  ${testReport}
  EOF
  echo ""
  echo "Tests: ${toString (builtins.length tests)} total, ${toString (builtins.length tests - builtins.length failedTests)} passed, ${toString (builtins.length failedTests)} failed"
  ${if allPassed then ''
    echo "All tests passed!"
    touch $out
  '' else ''
    echo ""
    echo "Failed tests:"
    cat <<'EOF'
    ${failedReport}
    EOF
    exit 1
  ''}
''
