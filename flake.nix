{
  description = "GS specific config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";

    opsctl = {
      # TODO: use tag instead commit hash
      # There seems to be a bug with private repositories because the tag reference doesn't work
      url = "git+ssh://git@github.com/giantswarm/opsctl.git?rev=24b44616b0729522fe2ab2527309d4fa61ee97cc";
      flake = false;
    };

    kubectl-gs = {
      url = "github:giantswarm/kubectl-gs?ref=v4.0.0";
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
