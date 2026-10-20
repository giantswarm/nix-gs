{ inputs }:
final: prev: {
  opsctl = final.callPackage ./packages/opsctl.nix { };
  envctl = final.callPackage ./packages/envctl.nix { };
  architect = final.callPackage ./packages/architect.nix { };
  # kubectl-gs >= 5.10 requires go >= 1.27 in go.mod; nixpkgs default is older.
  kubectl-gs = final.callPackage ./packages/kubectl-gs.nix {
    buildGoModule = final.buildGo127Module;
  };
  muster = final.callPackage ./packages/muster.nix { };
  devctl = final.callPackage ./packages/devctl.nix { };
  konfigure = final.callPackage ./packages/konfigure.nix { };
  gitsemver = final.callPackage ./packages/gitsemver.nix { };
}
