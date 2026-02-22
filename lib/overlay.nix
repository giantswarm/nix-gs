{ inputs }:
final: prev: {
  opsctl = final.callPackage ./packages/opsctl.nix { };
  envctl = final.callPackage ./packages/envctl.nix { };
  architect = final.callPackage ./packages/architect.nix { };
  kubectl-gs = final.callPackage ./packages/kubectl-gs.nix { };
  muster = final.callPackage ./packages/muster.nix { };
  devctl = final.callPackage ./packages/devctl.nix { };
  konfigure = final.callPackage ./packages/konfigure.nix { };
}
