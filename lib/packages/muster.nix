{ pkgs, buildGoModule }:
let
  meta = builtins.fromJSON (builtins.readFile ./muster.json);
in
buildGoModule rec {
  pname = "muster";
  version = meta.version;

  src = pkgs.fetchFromGitHub {
    owner = meta.owner;
    repo = meta.repo;
    rev = "v${version}";
    hash = meta.hash;
  };

  vendorHash = meta.vendorHash;

  doCheck = false;

  env.CGO_ENABLED = 0;

  ldflags = [
    "-w"
  ];
}
