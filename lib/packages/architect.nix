{ pkgs, buildGoModule }:
let
  meta = builtins.fromJSON (builtins.readFile ./architect.json);
in
buildGoModule rec {
  pname = "architect";
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
    "-X 'github.com/giantswarm/architect/pkg/project.gitSHA=${src.rev}'"
  ];
}
