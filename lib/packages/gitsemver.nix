{ pkgs, buildGoModule }:
let
  meta = builtins.fromJSON (builtins.readFile ./gitsemver.json);
in
buildGoModule rec {
  pname = "gitsemver";
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
    "-X 'github.com/giantswarm/gitsemver/v2/pkg/project.gitSHA=${src.rev}'"
  ];
}
