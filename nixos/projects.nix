{ config, lib, ... }:
{
  my.projects = lib.mkIf config.my.nix-gs.enable {
    projects = import ../files/projects.nix;
  };
}
