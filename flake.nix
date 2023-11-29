{
  description = "GS specific config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";

    opsctl = {
      url = "git+ssh://git@github.com/giantswarm/opsctl.git?rev=18146a44e3d9c55fb4657ac5b80eb33721561891";
      flake = false;
    };

    kubectl-gs = {
      url = "github:giantswarm/kubectl-gs?ref=v2.48.0";
      flake = false;
    };
  };

  outputs = inputs @ { nixpkgs, flake-utils, ... }:
    let
      mkOverlays = { pkgs }: [
        (import ./lib/overlay.nix { inherit pkgs inputs; })
      ];
    in
    (flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = mkOverlays { inherit pkgs; };
        };
      in {
        packages = {
          inherit (pkgs) opsctl kubectl-gs;
          default = pkgs.opsctl;
        };
      })) // {
        lib = { inherit mkOverlays; };
      };
}
