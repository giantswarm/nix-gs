{ inputs }:
final: prev: {
  opsctl = final.callPackage ./opsctl.nix { };
  kubectl-gs = final.callPackage ./kubectl-gs.nix { };
  envctl = final.callPackage ./envctl.nix { };
}
