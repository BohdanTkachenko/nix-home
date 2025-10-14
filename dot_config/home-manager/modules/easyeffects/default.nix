{ pkgs, ... }:

let
  lib = pkgs.lib;

  presetsPath = ./presets/JackHack96;
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

  # Declaratively manage the IRS files
  home.file =
    let
      irsFilenames = lib.attrNames (builtins.readDir irsPath);
    in
    lib.listToAttrs (map (filename: {
      name = ".config/easyeffects/irs/${filename}";
      value = {
        source = irsPath + "/${filename}";
      };
    }) irsFilenames);
}
