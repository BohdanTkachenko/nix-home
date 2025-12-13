{ lib, ... }:
{
  options.custom = {
    profile = lib.mkOption {
      type = lib.types.enum [
        "personal"
        "work"
      ];
      description = "The profile type (personal or work) for environment-specific configuration.";
    };
  };
}
