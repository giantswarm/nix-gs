{ pkgs, buildGoModule }:
let
  meta = builtins.fromJSON (builtins.readFile ./agentlab.json);
in
buildGoModule rec {
  pname = "agentlab";
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

  subPackages = [ "." ];

  ldflags = [
    "-w"
    "-X 'github.com/giantswarm/agentlab/pkg/project.version=${version}'"
  ];
}
