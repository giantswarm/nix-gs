{ config, lib, ... }:
{
  my.features.projects = lib.mkIf config.my.features.nix-gs.enable {
    projects = import ../files/projects.nix;
  };
}
