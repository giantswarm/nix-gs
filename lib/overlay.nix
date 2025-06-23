{ inputs }:
final: prev: {
  opsctl = final.callPackage ./opsctl.nix { src = inputs.opsctl; };
  kubectl-gs = final.callPackage ./kubectl-gs.nix { };
  envctl = final.callPackage ./envctl.nix { };
}
