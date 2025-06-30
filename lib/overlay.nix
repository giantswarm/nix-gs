{ inputs }:
final: prev: {
  opsctl = final.callPackage ./opsctl.nix { };
  envctl = final.callPackage ./envctl.nix { };
  kubectl-gs = final.callPackage ./kubectl-gs.nix { };
  muster = final.callPackage ./muster.nix { };
}
