{ config, lib, ... }:
{
  my.features.projects = lib.mkIf config.my.nix-gs.enable {
    projects = import ../files/projects.nix;
  };
}
