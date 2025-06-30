{ inputs }:
final: prev: {
  opsctl = final.callPackage ./opsctl.nix { };
  kubectl-gs = final.callPackage ./kubectl-gs.nix { };
  muster = final.callPackage ./muster.nix { };
}
