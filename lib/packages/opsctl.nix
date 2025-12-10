{ buildGoModule }:
let
  meta = builtins.fromJSON (builtins.readFile ./opsctl.json);
in
buildGoModule rec {
  pname = "opsctl";
  version = meta.version;

  src = builtins.fetchGit {
    url = meta.url;
    ref = "v${version}";
    rev = meta.rev;
  };

  vendorHash = meta.vendorHash;

  env.CGO_ENABLED = 0;

  ldflags = [
    "-w"
    "-X 'github.com/giantswarm/opsctl/v5/pkg/project.gitSHA=${src.rev}'"
  ];
}
