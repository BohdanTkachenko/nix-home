# Common LUKS + Btrfs disk configuration
{
  config,
  lib,
  ...
}:
let
  cfg = config.my.disk;
in
{
  options.my.disk = {
    enable = lib.mkEnableOption "LUKS + Btrfs disk layout";
    diskDevice = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Disk device path for the LUKS + Btrfs setup";
    };
  };

  config = lib.mkIf cfg.enable {
    disko.devices = {
      disk = {
        main = {
          device = cfg.diskDevice;
          type = "disk";
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                size = "2G";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [ "umask=0077" ];
                };
              };

              luks = {
                size = "100%";
                content = {
                  type = "luks";
                  name = "cryptroot";
                  settings = {
                    allowDiscards = true;
                    bypassWorkqueues = true;
                  };
                  content = {
                    type = "btrfs";
                    extraArgs = [ "-f" ];
                    subvolumes = {
                      "@" = {
                        mountpoint = "/";
                        mountOptions = [
                          "compress=zstd"
                          "noatime"
                        ];
                      };
                      "@home" = {
                        mountpoint = "/home";
                        mountOptions = [
                          "compress=zstd"
                          "noatime"
                        ];
                      };
                      "@nix" = {
                        mountpoint = "/nix";
                        mountOptions = [
                          "compress=zstd"
                          "noatime"
                        ];
                      };
                      "@persist" = {
                        mountpoint = "/persist";
                        mountOptions = [
                          "compress=zstd"
                          "noatime"
                        ];
                      };
                      "@swap" = {
                        mountpoint = "/swap";
                        swap.swapfile.size = "72G";
                      };
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
