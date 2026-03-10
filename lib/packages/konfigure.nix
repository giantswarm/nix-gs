{ pkgs, buildGoModule }:
let
  meta = builtins.fromJSON (builtins.readFile ./konfigure.json);
in
buildGoModule rec {
  pname = "konfigure";
  version = meta.version;

  src = pkgs.fetchFromGitHub {
    owner = meta.owner;
    repo = meta.repo;
    rev = "v${version}";
    hash = meta.hash;
  };

  vendorHash = meta.vendorHash;

  env.CGO_ENABLED = 0;

  doCheck = false;

  ldflags = [
    "-w"
  ];
}
