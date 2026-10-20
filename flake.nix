{
  description = "GS specific config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    inputs@{ nixpkgs, flake-utils, ... }:
    let
      overlay = import ./lib/overlay.nix { inherit inputs; };
      packageNames = import ./lib/package-names.nix;
    in
    (flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ overlay ];
        };
        packages = nixpkgs.lib.genAttrs packageNames (name: pkgs.${name});
      in
      {
        inherit packages;
        checks = packages;
      }
    ))
    // {
      inherit overlay;
      homeManagerModules = {
        projects = import ./nixos/projects.nix;
        packages = import ./nixos/packages.nix;
        golang = import ./nixos/golang.nix;
      };
    };
}
