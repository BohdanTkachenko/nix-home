{ ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      jj-worktree = final.callPackage ./jj-worktree.nix { };
    })
  ];
}
