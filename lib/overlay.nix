{ inputs }:
final: prev:
let
  # Extra `callPackage` arguments for packages that need them.
  overrides = {
    # kubectl-gs >= 5.10 requires go >= 1.27 in go.mod; nixpkgs default is older.
    kubectl-gs.buildGoModule = final.buildGo127Module;
  };
in
builtins.listToAttrs (
  map (name: {
    inherit name;
    value = final.callPackage ./packages/${name}.nix (overrides.${name} or { });
  }) (import ./package-names.nix)
)
