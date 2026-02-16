{ pkgs, ... }:

let
  lib = pkgs.lib;

  presetsRepo = pkgs.fetchFromGitHub {
    owner = "JackHack96";
    repo = "EasyEffects-Presets";
    rev = "d77a61eb01c36e2c794bddc25423445331e99915";
    hash = "sha256-or5kH/vTwz7IO0Vz7W4zxK2ZcbL/P3sO9p5+EdcC2DA=";
  };

  presetsPath = presetsRepo;
  irsPath = presetsPath + "/irs";

  loadPreset = filename: {
    name = lib.strings.removeSuffix ".json" filename;
    value = builtins.fromJSON (builtins.readFile (presetsPath + "/${filename}"));
  };
in
{
  services.easyeffects.enable = true;

  services.easyeffects.extraPresets =
    let
      allFilenames = lib.attrNames (builtins.readDir presetsPath);
      jsonFilenames = lib.filter (filename: lib.strings.hasSuffix ".json" filename) allFilenames;
    in
    lib.listToAttrs (map loadPreset jsonFilenames);

  home.file =
    let
      irsFilenames = lib.attrNames (builtins.readDir irsPath);
    in
    lib.listToAttrs (
      map (filename: {
        name = ".config/easyeffects/irs/${filename}";
        value = {
          source = irsPath + "/${filename}";
        };
      }) irsFilenames
    );
}
