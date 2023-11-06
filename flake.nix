{
  description = "GS specific config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";

    opsctl = {
      url = "git+ssh://git@github.com/giantswarm/opsctl.git?rev=18146a44e3d9c55fb4657ac5b80eb33721561891";
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
      in {
        packages = {
          inherit opsctl;
          default = opsctl;
        };
      });
}
