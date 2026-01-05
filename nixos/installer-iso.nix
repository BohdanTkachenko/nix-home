# Build with: nix build .#nixosConfigurations.installer-iso.config.system.build.isoImage
{
  lib,
  pkgs,
  modulesPath,
  self,
  targetConfig,
  ...
}:
let
  # Extract flake inputs to cache them
  flakeOutPaths =
    let
      collector =
        parent:
        map (
          child:
          [ child.outPath ] ++ (if child ? inputs && child.inputs != { } then (collector child) else [ ])
        ) (lib.attrValues parent.inputs);
    in
    lib.unique (lib.flatten (collector self));

  # Define the closure we want available offline
  dependencies = [
    targetConfig.config.system.build.toplevel
    targetConfig.config.system.build.diskoScript
    targetConfig.config.system.build.diskoScript.drvPath
    targetConfig.pkgs.stdenv.drvPath
    targetConfig.pkgs.perlPackages.ConfigIniFiles
    targetConfig.pkgs.perlPackages.FileSlurp
  ]
  ++ flakeOutPaths;

  secureBootScript = pkgs.callPackage ../scripts/init-secureboot.nix { };
  
  configureTargetScript = pkgs.writeShellScript "configure-target-system" ''
    set -euo pipefail
    ${secureBootScript}/bin/init-secureboot
  '';

  targetDisk = targetConfig.config.disko.devices.disk.main.device;
  targetUser = targetConfig.config.users.users.dan.name;
  installScriptName = "dan-install-nixos";

  installScript = pkgs.writeShellScriptBin installScriptName ''
    set -eu

    echo "Device information:"
    lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS,MODEL,SERIAL "${targetDisk}"
    echo

    RED='\033[0;31m'
    NC='\033[0m'
    echo -e "''${RED}This script will partition and format ${targetDisk}, destroying all data on it.''${NC}"
    echo -e "''${RED}Please review the device information and confirm you want to proceed.''${NC}"
    echo -e "''${RED}Type 'yes' to continue:''${NC}"
    read -r confirmation
    if [[ "$confirmation" != "yes" ]]; then
        echo "Aborting installation."
        exit 1
    fi

    echo "Confirmation received. Starting installation..."
    echo

    echo "1. Partitioning..."
    ${targetConfig.config.system.build.diskoScript}

    echo "2. Installing system..."
    nixos-install --system ${targetConfig.config.system.build.toplevel} --no-root-passwd --no-bootloader

    echo "3. Configuring Boot & Security..."
    cp ${configureTargetScript} /mnt/configure-target.sh
    nixos-enter --root /mnt --command "bash /configure-target.sh"
    rm /mnt/configure-target.sh

    echo "4. Setting User Password..."
    echo "Please set the password for user '${targetUser}':"
    nixos-enter --root /mnt --command "passwd ${targetUser}"

    echo "5. Done! Reboot and remove media."
  '';
in
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  nixpkgs.config.allowUnfree = true;
  hardware.enableAllFirmware = true;

  # Force offline mode
  networking.wireless.enable = lib.mkForce false;
  networking.useDHCP = lib.mkForce false;
  networking.dhcpcd.enable = false;

  nix.settings = {
    substituters = lib.mkForce [ ];
    connect-timeout = 0;
    min-free = 0;
    max-jobs = "auto";
  };

  isoImage.squashfsCompression = "zstd -Xcompression-level 6";

  image.fileName = lib.mkForce "nixos-dan.iso";
  isoImage.volumeID = lib.mkForce "NIXOS_CUSTOM";
  isoImage.storeContents = dependencies;

  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 10;
    };
    efi.canTouchEfiVariables = true;
  };

  # Include flake for reference in the live environment
  environment.etc."nixos-config".source = self;

  environment.systemPackages = with pkgs; [
    installScript

    git
    parted
    gptfdisk
    cryptsetup
    btrfs-progs
    rsync
    htop
    pciutils
    usbutils
  ];

  users.motd = ''
    To install NixOS, run:
    $ sudo ${installScriptName}
  '';
}
