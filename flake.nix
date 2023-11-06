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
      url = "github:giantswarm/kubectl-gs?ref=v2.45.3";
      flake = false;
    };
  };

  outputs = inputs @ { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [];
        };

        opsctl = pkgs.callPackage ./lib/opsctl.nix { src = inputs.opsctl; };
        kubectl-gs = pkgs.callPackage ./lib/kubectl-gs.nix { src = inputs.kubectl-gs; };
      in {
        packages = {
          inherit opsctl kubectl-gs;
          default = opsctl;
        };
      });
}
