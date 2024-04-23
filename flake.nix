{
  description = "GS specific config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";

    opsctl = {
      # TODO: use tag instead commit hash
      # There seems to be a bug with private repositories because the tag reference doesn't work
      url = "git+ssh://git@github.com/giantswarm/opsctl.git?rev=330f43c7afe4b626a31e0c2932c26347fcd3e85f";
      flake = false;
    };

    kubectl-gs = {
      url = "github:giantswarm/kubectl-gs?ref=v2.52.1";
      flake = false;
    };
  };

  outputs = inputs @ { nixpkgs, flake-utils, ... }:
    let
      overlay = import ./lib/overlay.nix { inherit inputs; };
    in
    (flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [overlay];
        };
      in {
        packages = {
          inherit (pkgs) opsctl kubectl-gs;
          default = pkgs.opsctl;
        };
      })) // {
        inherit overlay;
      };
}
