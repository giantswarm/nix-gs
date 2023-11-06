{ pkgs, inputs }:
final: prev: {
  opsctl = pkgs.callPackage ./opsctl.nix { src = inputs.opsctl; };
  kubectl-gs = pkgs.callPackage ./kubectl-gs.nix { src = inputs.kubectl-gs; };
}
