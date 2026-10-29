{ inputs }:
final: prev:
let
  # Giant Swarm repos track the latest Go in go.mod, ahead of nixpkgs' default
  # `buildGoModule`. Build every package with it; bump here when go.mod moves on.
  defaults = {
    buildGoModule = final.buildGo127Module;
  };

  # Extra `callPackage` arguments for packages that need them.
  overrides = { };
in
builtins.listToAttrs (
  map (name: {
    inherit name;
    value = final.callPackage ./packages/${name}.nix (defaults // overrides.${name} or { });
  }) (import ./package-names.nix)
)
