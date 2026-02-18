{ pkgs, lib, config, ... }:
let
  userNames = builtins.attrNames config.my.users;
  indexedUsers = lib.imap0 (i: name: { inherit i name; }) userNames;
in
{
  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  environment.systemPackages = with pkgs; [
    podman-compose
  ];

  users.groups.podman.members = userNames;

  # Rootless podman support for all users
  users.users = builtins.listToAttrs (map (u: {
    name = u.name;
    value = {
      linger = true;

      subUidRanges = [
        {
          startUid = 100000 + u.i * 65536;
          count = 65536;
        }
      ];

      subGidRanges = [
        {
          startGid = 100000 + u.i * 65536;
          count = 65536;
        }
      ];
    };
  }) indexedUsers);
}
