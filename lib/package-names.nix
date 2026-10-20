# Every package is a `packages/<name>.nix` file; its name is the file's basename.
# The overlay, the flake's packages/checks and the Home Manager packages module
# all derive from this list, so adding a package means adding its two files.
let
  files = builtins.readDir ./packages;
  nixFiles = builtins.filter (f: files.${f} == "regular" && builtins.match ".*\\.nix" f != null) (
    builtins.attrNames files
  );
in
map (f: builtins.substring 0 (builtins.stringLength f - 4) f) nixFiles
