# Installs every package nix-gs provides. Expects `pkgs` to carry the nix-gs
# overlay.
{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.packages = lib.mkIf config.my.features.nix-gs.enable (
    map (name: pkgs.${name}) (import ../lib/package-names.nix)
  );
}
