# NixOS-only capability toggles.
#
# my.gui.enable is declared in home/modules/options.nix, which is shared into
# both the NixOS and home-manager module sets via overlays/default.nix — so it
# is already available here and must NOT be re-declared (that would collide).
#
# my.gaming — Steam, gamemode, Waydroid, Minecraft. Implies a graphical
# session, so it defaults to my.gui.enable but can be toggled independently
# (e.g. a desktop with no games).
{ config, lib, ... }:
{
  options.my.gaming.enable = lib.mkOption {
    type = lib.types.bool;
    default = config.my.gui.enable;
    defaultText = lib.literalExpression "config.my.gui.enable";
    description = "Gaming stack (Steam, gamemode, Waydroid, Minecraft). Requires a graphical session.";
  };

  # Lanzaboote secure boot and the TPM2-unlocked LUKS initrd. On by default for
  # the physical machines; cloud/UEFI hosts disable it to boot without secure
  # boot or encryption.
  options.my.secureBoot.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Lanzaboote secure boot and TPM2 LUKS initrd.";
  };
}
